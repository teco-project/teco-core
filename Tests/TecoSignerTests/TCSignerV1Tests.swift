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

final class TCSignerV1Tests: XCTestCase {

    let credential: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY")
    let credentialWithSessionToken: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY", token: "MY_TC_SESSION_TOKEN")

    let tcSampleCredential: Credential = StaticCredential(secretId: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******", secretKey: "Gu5t9xGARNpq86cd98joQYCN3*******")
    let tcSampleDate: Date = Date(timeIntervalSince1970: 1465185768)

    let tcSHA256SampleCredential: Credential = StaticCredential(secretId: "AKIDT8G5**********ooNq1rFSw1fyBVCX9D", secretKey: "pxPgRWD******qBTDk7WmeRZSmPco0")
    let tcSHA256SampleDate: Date = Date(timeIntervalSince1970: 1502197934)

    // - MARK: Examples by API Explorer - https://console.cloud.tencent.com/api/explorer

    func testSignGetRequest() throws {
        let signer = TCSignerV1(credential: credential)
        let signedURL = try signer.signURL(
            url: "https://cvm.tencentcloudapi.com/?Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Region=ap-shanghai&Version=2017-03-12",
            nonce: 8938,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedURL,
            URL(string: "https://cvm.tencentcloudapi.com/?Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Nonce=8938&Region=ap-shanghai&SecretId=MY_TC_SECRET_ID&Signature=tJ8iV7prk8YIzmTwwnjVmN9hlTQ%3D&Timestamp=1000000000&Version=2017-03-12")
        )
    }

    func testSignPostRequest() throws {
        let signer = TCSignerV1(credential: credential)
        let signedBody = try signer.signBody(
            url: "https://cvm.tencentcloudapi.com",
            queryItems: [
                .init(name: "Action", value: "DescribeInstances"),
                .init(name: "InstanceIds.0", value: "ins-000000"),
                .init(name: "InstanceIds.1", value: "ins-000001"),
                .init(name: "Language", value: "zh-CN"),
                .init(name: "Region", value: "ap-shanghai"),
                .init(name: "Version", value: "2017-03-12"),
                
            ],
            nonce: 5860,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            String(data: signedBody, encoding: .ascii),
            "Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Nonce=5860&Region=ap-shanghai&SecretId=MY_TC_SECRET_ID&Signature=ve2J8iIYWjHzJpsAFONELiSMbNA%3D&Timestamp=1000000000&Version=2017-03-12"
        )
    }

    // - MARK: Special query parameters

    func testEmptyQueryParameter() throws {
        let signer = TCSignerV1(credential: credential)
        let signedURL = try signer.signURL(
            url: "https://region.tencentcloudapi.com/?Action=DescribeRegions&Product=cvm&Region=&Version=2022-06-27",
            nonce: 2173,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedURL,
            URL(string: "https://region.tencentcloudapi.com/?Action=DescribeRegions&Nonce=2173&Product=cvm&Region=&SecretId=MY_TC_SECRET_ID&Signature=hMNWNgTcFjUZB7yVetq2wxeUjzE%3D&Timestamp=1000000000&Version=2022-06-27")!
        )
    }

    func testLeastParameters() throws {
        let signer = TCSignerV1(credential: credential)
        let signedBody = try signer.signBody(
            url: "https://region.tencentcloudapi.com",
            queryItems: [
                .init(name: "Action", value: "DescribeProducts"),
                .init(name: "Version", value: "2022-06-27"),
            ],
            nonce: 6457,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            String(data: signedBody, encoding: .ascii),
            "Action=DescribeProducts&Nonce=6457&SecretId=MY_TC_SECRET_ID&Signature=orvrFH0%2FX202yBYL1kDjJ2RG%2Bgo%3D&Timestamp=1000000000&Version=2022-06-27"
        )
    }

    func testUnicodeParameter() throws {
        let signer = TCSignerV1(credential: credential)
        let signedBody = try signer.signBody(
            url: "https://tag.tencentcloudapi.com/",
            queryItems: [
                .init(name: "Action", value: "GetTagValues"),
                .init(name: "Version", value: "2018-08-13"),
                .init(name: "TagKeys.0", value: "平台"),
            ],
            nonce: 4906,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            String(data: signedBody, encoding: .ascii),
            "Action=GetTagValues&Nonce=4906&SecretId=MY_TC_SECRET_ID&Signature=wC32%2Bfkn0vo3B8Ap0yQEWn0gzFc%3D&TagKeys.0=%E5%B9%B3%E5%8F%B0&Timestamp=1000000000&Version=2018-08-13"
        )
    }

    func testPercentEncodedParameter() throws {
        let signer = TCSignerV1(credential: credential)
        let signedURL = try signer.signURL(
            url: "https://tag.tencentcloudapi.com/?Action=GetTagValues&Version=2018-08-13&TagKeys.0=%E5%B9%B3%E5%8F%B0",
            nonce: 4906,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedURL,
            URL(string: "https://tag.tencentcloudapi.com/?Action=GetTagValues&Nonce=4906&SecretId=MY_TC_SECRET_ID&Signature=UjS7bczn21DgMabt7pq74p7pCVs%3D&TagKeys.0=%E5%B9%B3%E5%8F%B0&Timestamp=1000000000&Version=2018-08-13")!
        )
    }

    func testCanonicalRequest() throws {
        let url = URLComponents(string: "https://test.com/?item=apple&hello")!
        let signer = TCSignerV1(credential: credential)
        let requestString = signer.requestString(items: url.queryItems!)
        XCTAssertEqual(requestString, "hello=&item=apple")

        let signingData = TCSignerV1.SigningData(host: url.host, path: url.path, queryItems: url.queryItems, method: .POST)
        let signatureOriginalString = signer.signatureOriginalString(signingData: signingData)
        XCTAssertEqual(signatureOriginalString, "POSTtest.com/?hello=&item=apple")
    }

    // MARK: - Output encoding validity

    func testRFC3986Output() throws {
        let signer = TCSignerV1(credential: credential)
        let signedURL = try signer.signURL(
            url: "https://tag.tencentcloudapi.com/?Action=GetTagValues&Version=2018-08-13&TagKeys.0=%E5%B9%B3%E5%8F%B0",
            nonce: 7263,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            signedURL,
            URL(string: "https://tag.tencentcloudapi.com/?Action=GetTagValues&Nonce=7263&SecretId=MY_TC_SECRET_ID&Signature=TEsFnzRNdY%2Bv6g5aVJ%2BGSM4zmgE%3D&TagKeys.0=%E5%B9%B3%E5%8F%B0&Timestamp=1000000000&Version=2018-08-13")!
        )
    }

    func testWWWFormURLEncodedOutput() throws {
        let signer = TCSignerV1(credential: credential)
        let signedBody = try signer.signBody(
            url: "https://tag.tencentcloudapi.com",
            queryItems: [
                .init(name: "Action", value: "GetTagValues"),
                .init(name: "Version", value: "2018-08-13"),
                .init(name: "TagKeys.0", value: "业务 后台"),
            ],
            nonce: 2353,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            String(data: signedBody, encoding: .ascii),
            "Action=GetTagValues&Nonce=2353&SecretId=MY_TC_SECRET_ID&Signature=Cuwf%2Bs8Br8SzRIVahjs7GleQTLQ%3D&TagKeys.0=%E4%B8%9A%E5%8A%A1+%E5%90%8E%E5%8F%B0&Timestamp=1000000000&Version=2018-08-13"
        )
    }

    // MARK: - Tencent Cloud signer samples

    // https://cloud.tencent.com/document/api/213/30654
    func testTencentCloudSample() throws {
        let signer = TCSignerV1(credential: tcSampleCredential)
        let queryItems = signer.signQueryItems(
            host: "cvm.tencentcloudapi.com",
            queryItems: [
                .init(name: "Action", value: "DescribeInstances"),
                .init(name: "InstanceIds.0", value: "ins-09dx96dg"),
                .init(name: "Limit", value: "20"),
                .init(name: "Nonce", value: "11886"),
                .init(name: "Offset", value: "0"),
                .init(name: "Region", value: "ap-guangzhou"),
                .init(name: "SecretId", value: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******"),
                .init(name: "Timestamp", value: "1465185768"),
                .init(name: "Version", value: "2017-03-12"),
            ],
            method: .GET,
            nonce: 11886,
            date: tcSampleDate
        )
        XCTAssertEqual(
            queryItems,
            [
                .init(name: "Action", value: "DescribeInstances"),
                .init(name: "InstanceIds.0", value: "ins-09dx96dg"),
                .init(name: "Limit", value: "20"),
                .init(name: "Nonce", value: "11886"),
                .init(name: "Offset", value: "0"),
                .init(name: "Region", value: "ap-guangzhou"),
                .init(name: "SecretId", value: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******"),
                .init(name: "Signature", value: "zmmjn35mikh6pM3V7sUEuX4wyYM="),
                .init(name: "Timestamp", value: "1465185768"),
                .init(name: "Version", value: "2017-03-12"),
            ]
        )
    }

    // https://cloud.tencent.com/document/api/228/10771
    func testTencentCloudSHA256Sample() throws {
        let signer = TCSignerV1(credential: tcSHA256SampleCredential)
        let queryItems = signer.signQueryItems(
            host: "cdn.api.qcloud.com",
            path: "/v2/index.php",
            queryItems: [
                .init(name: "Action", value: "DescribeCdnHosts"),
                .init(name: "SecretId", value: "AKIDT8G5**********ooNq1rFSw1fyBVCX9D"),
                .init(name: "Timestamp", value: "1502197934"),
                .init(name: "Nonce", value: "48059"),
                .init(name: "SignatureMethod", value: "HmacSHA256"),
                .init(name: "offset", value: "0"),
                .init(name: "limit", value: "10"),
            ],
            method: .GET,
            algorithm: .hmacSHA256,
            nonce: 48059,
            date: tcSHA256SampleDate
        )
        // This is manually computed since the document is wrong.
        XCTAssertEqual(
            queryItems,
            [
                .init(name: "Action", value: "DescribeCdnHosts"),
                .init(name: "Nonce", value: "48059"),
                .init(name: "SecretId", value: "AKIDT8G5**********ooNq1rFSw1fyBVCX9D"),
                .init(name: "Signature", value: "8GGNfQ1HXC/JkCjUugwXZKtKuMmkbX9lPxtDdkfNxy8="),
                .init(name: "SignatureMethod", value: "HmacSHA256"),
                .init(name: "Timestamp", value: "1502197934"),
                .init(name: "limit", value: "10"),
                .init(name: "offset", value: "0"),
            ]
        )
    }
}
