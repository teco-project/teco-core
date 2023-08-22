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

import NIOCore
import NIOHTTP1
@testable import TecoSigner
import XCTest

final class TCSignerV1Tests: XCTestCase {
    let credential: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY")
    let credentialWithSessionToken: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY", token: "MY_TC_SESSION_TOKEN")
    let tcSampleCredential: Credential = StaticCredential(secretId: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******", secretKey: "Gu5t9xGARNpq86cd98joQYCN3*******")
    let tcSampleDate: Date = Date(timeIntervalSince1970: 1465185768)

    // - MARK: Examples by API Explorer - https://console.cloud.tencent.com/api/explorer

    func testSignGetRequest() throws {
        let signer = TCSignerV1(credential: credential)
        let query = try signer.signQueryString(
            url: "https://cvm.tencentcloudapi.com/?Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Region=ap-shanghai&Version=2017-03-12",
            nonce: 8938,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            query,
            "Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Nonce=8938&Region=ap-shanghai&SecretId=MY_TC_SECRET_ID&Signature=tJ8iV7prk8YIzmTwwnjVmN9hlTQ%3D&Timestamp=1000000000&Version=2017-03-12"
        )
    }

    func testSignPostRequest() throws {
        let signer = TCSignerV1(credential: credential)
        let query = try signer.signQueryString(
            url: "https://cvm.tencentcloudapi.com",
            query: "Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Region=ap-shanghai&Version=2017-03-12",
            nonce: 5860,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            query,
            "Action=DescribeInstances&InstanceIds.0=ins-000000&InstanceIds.1=ins-000001&Language=zh-CN&Nonce=5860&Region=ap-shanghai&SecretId=MY_TC_SECRET_ID&Signature=ve2J8iIYWjHzJpsAFONELiSMbNA%3D&Timestamp=1000000000&Version=2017-03-12"
        )
    }

    // - MARK: More test cases

    func testEmptyQueryParameter() throws {
        let signer = TCSignerV1(credential: credential)
        let query = try signer.signQueryString(
            url: "https://region.tencentcloudapi.com/?Action=DescribeRegions&Product=cvm&Region=&Version=2022-06-27",
            nonce: 2173,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            query,
            "Action=DescribeRegions&Nonce=2173&Product=cvm&Region=&SecretId=MY_TC_SECRET_ID&Signature=hMNWNgTcFjUZB7yVetq2wxeUjzE%3D&Timestamp=1000000000&Version=2022-06-27"
        )
    }

    func testLeastParameters() throws {
        let signer = TCSignerV1(credential: credential)
        let query = try signer.signQueryString(
            url: "https://region.tencentcloudapi.com",
            query: "Action=DescribeProducts&Version=2022-06-27",
            nonce: 6457,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            query,
            "Action=DescribeProducts&Nonce=6457&SecretId=MY_TC_SECRET_ID&Signature=orvrFH0%2FX202yBYL1kDjJ2RG%2Bgo%3D&Timestamp=1000000000&Version=2022-06-27"
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

    // MARK: - Tencent Cloud Signer samples

    // https://cloud.tencent.com/document/api/213/30654
    func testTencentCloudSample() throws {
        let signer = TCSignerV1(credential: tcSampleCredential)
        let query = signer.signQueryString(
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
            nonce: 11886,
            date: tcSampleDate
        )
        XCTAssertEqual(
            query,
            "Action=DescribeInstances&InstanceIds.0=ins-09dx96dg&Limit=20&Nonce=11886&Offset=0&Region=ap-guangzhou&SecretId=AKIDz8krbsJ5yKBZQpn74WFkmLPx3*******&Signature=zmmjn35mikh6pM3V7sUEuX4wyYM%3D&Timestamp=1465185768&Version=2017-03-12"
        )
    }
}
