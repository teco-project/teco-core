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

final class COSSignerTests: XCTestCase {
    let credential: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY")
    let credentialWithToken: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY", token: "MY_TC_SESSION_TOKEN")

    func testCanonicalRequest() throws {
        let url = URLComponents(string: "https://test.com/%E7%A4%BA%E4%BE%8B%E6%96%87%E4%BB%B6.mp4?item=apple&hello")!

        let signingData = COSSigner.SigningData(
            path: url.path,
            method: .GET,
            headers: [:],
            parameters: url.queryItems,
            date: Date(timeIntervalSince1970: 432_831),
            duration: 3600
        )

        let signer = COSSigner(credential: credential)
        let httpString = signer.httpString(signingData: signingData)
        XCTAssertEqual(httpString, "get\n/示例文件.mp4\nhello=&item=apple\n\n")

        let stringToSign = signer.stringToSign(signingData: signingData)
        XCTAssertEqual(stringToSign, "sha1\n432831;436431\nd668fafd5fb6c543b39b14f2d7eec8b6472d350b\n")
    }

    // MARK: - Tencent Cloud signer examples

    // https://cloud.tencent.com/document/product/436/7778#.E4.B8.8A.E4.BC.A0.E5.AF.B9.E8.B1.A1
    func testTencentCloudPUTExample() throws {
        let credential = StaticCredential(secretId: "AKXXXXXXXXXXXXXXXXXXX", secretKey: "BQXXXXXXXXXXXXXXXXXXXX")
        let signer = COSSigner(credential: credential)
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
        let signer = COSSigner(credential: credential)
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
