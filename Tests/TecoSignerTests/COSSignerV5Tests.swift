//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOHTTP1
@testable import TecoSigner
import XCTest

final class COSSignerV5Tests: XCTestCase {
    let credential: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY")
    let credentialWithToken: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY", token: "MY_TC_SESSION_TOKEN")

    // MARK: - Examples by COS signing tool https://cos5.cloud.tencent.com/static/cos-sign/

    func testGETRequest() throws {
        let signer = COSSignerV5(credential: credential)
        let signedURL = try signer.signURL(
            url: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/test/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?response-expires=86400",
            headers: [
                "Host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
                "Range": "bytes=1000-",
                "If-Modified-Since": "800000000"
            ],
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedURL,
            URL(string: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/test/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?response-expires=86400&q-sign-algorithm=sha1&q-ak=MY_TC_SECRET_ID&q-sign-time=1000000000%3B1000000600&q-key-time=1000000000%3B1000000600&q-header-list=host%3Bif-modified-since%3Brange&q-url-param-list=response-expires&q-signature=b4b36de8277ad58c18a75aaa6ff16c82de20fc21")!
        )
    }

    func testPUTRequest() throws {
        let signer = COSSignerV5(credential: credential)
        let signedHeaders = try signer.signHeaders(
            url: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/test/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4",
            headers: [
                "Host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
                "Cache-Control": "max-age=86400",
                "Content-Encoding": "gzip",
                "Content-Type": "video/mp4",
                "x-cos-acl": "public-read",
            ],
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedHeaders["authorization"].first,
            "q-sign-algorithm=sha1&q-ak=MY_TC_SECRET_ID&q-sign-time=1000000000;1000000600&q-key-time=1000000000;1000000600&q-header-list=cache-control;content-encoding;content-type;host;x-cos-acl&q-url-param-list=&q-signature=4c201f82722a1070c0dd21923b553a1c36a50807"
        )
    }

    func testDELETERequest() throws {
        let signer = COSSignerV5(credential: credential)
        let signedURL = try signer.signURL(
            url: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/test/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?versionId=2",
            method: .DELETE,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedURL,
            URL(string: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/test/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?versionId=2&q-sign-algorithm=sha1&q-ak=MY_TC_SECRET_ID&q-sign-time=1000000000%3B1000000600&q-key-time=1000000000%3B1000000600&q-header-list=&q-url-param-list=versionid&q-signature=080bd7aa662dfec82dd19aafdcb0a3b485baa9ea")!
        )
    }

    func testPOSTRequest() throws {
        let signer = COSSignerV5(credential: credential)
        let signedHeaders = try signer.signHeaders(
            url: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/test/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?restore&versionId=1",
            method: .POST,
            headers: [
                "Host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
                "Content-Type": "application/xml",
            ],
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedHeaders["authorization"].first,
            "q-sign-algorithm=sha1&q-ak=MY_TC_SECRET_ID&q-sign-time=1000000000;1000000600&q-key-time=1000000000;1000000600&q-header-list=content-type;host&q-url-param-list=restore;versionid&q-signature=9966f2243fb3f6668f60cf821949d9eac814ab9a"
        )
    }

    // - MARK: Special query parameters

    func testCanonicalRequest() throws {
        let url = URLComponents(string: "https://test.com/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?item=apple&hello")!

        let signingData = COSSignerV5.SigningData(
            path: url.path,
            method: .GET,
            headers: [:],
            parameters: url.queryItems,
            date: Date(timeIntervalSince1970: 432_831),
            duration: 3600
        )

        let signer = COSSignerV5(credential: credential)
        let httpString = signer.httpString(signingData: signingData)
        XCTAssertEqual(httpString, "get\n/示例文件.mp4\nhello=&item=apple\n\n")

        let stringToSign = signer.stringToSign(signingData: signingData)
        XCTAssertEqual(stringToSign, "sha1\n432831;436431\nd668fafd5fb6c543b39b14f2d7eec8b6472d350b\n")
    }

    // MARK: - Tencent Cloud signer examples

    // https://cloud.tencent.com/document/product/436/7778#.E4.B8.8A.E4.BC.A0.E5.AF.B9.E8.B1.A1
    func testTencentCloudPUTExample() throws {
        let credential = StaticCredential(secretId: "AKXXXXXXXXXXXXXXXXXXX", secretKey: "BQXXXXXXXXXXXXXXXXXXXX")
        let signer = COSSignerV5(credential: credential)
        let authentication = signer.signRequest(
            method: .PUT,
            headers: [
                "Date": "Thu, 16 May 2019 06:45:51 GMT",
                "Host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
                "Content-Type": "text/plain",
                "Content-Length": "13",
                "Content-MD5": "mQ/fVh815F3k6TAUm8m0eg==",
                "x-cos-acl": "private",
                "x-cos-grant-read": #"uin="100000000011""#,
            ],
            path: "/exampleobject(腾讯云)",
            parameters: nil,
            date: Date(timeIntervalSince1970: 1557989151),
            duration: 7200
        )
        // This is manually computed since the document is not reproducible.
        XCTAssertEqual(
            authentication,
            [
                .init(name: "q-sign-algorithm", value: "sha1"),
                .init(name: "q-ak", value: "AKXXXXXXXXXXXXXXXXXXX"),
                .init(name: "q-sign-time", value: "1557989151;1557996351"),
                .init(name: "q-key-time", value: "1557989151;1557996351"),
                .init(name: "q-header-list", value: "content-length;content-md5;content-type;date;host;x-cos-acl;x-cos-grant-read"),
                .init(name: "q-url-param-list", value: ""),
                .init(name: "q-signature", value: "b114f579add23ddf6786dc0ea10518b8c22a1980"),
            ]
        )
    }

    // https://cloud.tencent.com/document/product/436/7778#.E4.B8.8B.E8.BD.BD.E5.AF.B9.E8.B1.A1
    func testTencentCloudGETExample() throws {
        let credential = StaticCredential(secretId: "AKXXXXXXXXXXXXXXXXXXX", secretKey: "BQXXXXXXXXXXXXXXXXXXXX")
        let signer = COSSignerV5(credential: credential)
        let authentication = signer.signRequest(
            method: .GET,
            headers: [
                "Date": "Thu, 16 May 2019 06:55:53 GMT",
                "Host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
            ],
            path: "/exampleobject(腾讯云)",
            parameters: [
                .init(name: "response-content-type", value: "application/octet-stream"),
                .init(name: "response-cache-control", value: "max-age=600"),
            ],
            date: Date(timeIntervalSince1970: 1557989753),
            duration: 7200
        )
        // This is manually computed since the document is not reproducible.
        XCTAssertEqual(
            authentication,
            [
                .init(name: "q-sign-algorithm", value: "sha1"),
                .init(name: "q-ak", value: "AKXXXXXXXXXXXXXXXXXXX"),
                .init(name: "q-sign-time", value: "1557989753;1557996953"),
                .init(name: "q-key-time", value: "1557989753;1557996953"),
                .init(name: "q-header-list", value: "date;host"),
                .init(name: "q-url-param-list", value: "response-cache-control;response-content-type"),
                .init(name: "q-signature", value: "c0a4b2624604122903bb4cbaa4456d20db9c63db"),
            ]
        )
    }
}
