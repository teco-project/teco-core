//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022-2023 the Teco project authors
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

final class TCSignerV3Tests: XCTestCase {
    let credential: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY")
    let credentialWithToken: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY", token: "MY_TC_SESSION_TOKEN")

    // - MARK: Minimal signing by API Explorer - https://console.cloud.tencent.com/api/explorer

    func testMinimalSignPOSTRequest() throws {
        let signer = TCSignerV3(credential: credential, service: "cvm")
        let headers = try signer.signHeaders(
            url: "https://cvm.tencentcloudapi.com",
            method: .POST,
            headers: ["content-type": "application/json"],
            body: .string("{}"),
            mode: .minimal,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/cvm/tc3_request, SignedHeaders=content-type;host, Signature=2c0b761dcdeacac29ac9d135f9f22b0fa52d4536d8b7727a8a515935c47eaea7"
        )
    }

    func testMinimalSignGETRequest() throws {
        let signer = TCSignerV3(credential: credential, service: "cvm")
        let headers = try signer.signHeaders(
            url: "https://cvm.tencentcloudapi.com/?InstanceIds.0=ins-000000&InstanceIds.1=ins-000001",
            method: .GET,
            headers: ["content-type": "application/x-www-form-urlencoded"],
            mode: .minimal,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/cvm/tc3_request, SignedHeaders=content-type;host, Signature=a4315b91798a181a6e5fb0353590040a399edad4a003ef5688d71fb34366c471"
        )
    }

    // - MARK: Extended signing

    func testPOSTRequest() throws {
        let signer = TCSignerV3(credential: credential, service: "region")
        let headers = try signer.signHeaders(
            url: "https://region.tencentcloudapi.com",
            method: .POST,
            headers: [
                "content-type": "application/json",
                "x-tc-action": "DescribeRegions",
                "x-tc-version": "2022-06-27",
            ],
            body: .string(#"{"Product":"cvm"}"#),
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/region/tc3_request, SignedHeaders=content-type;host;x-tc-action;x-tc-content-sha256;x-tc-requestclient;x-tc-timestamp;x-tc-version, Signature=2e9e6e2b803969ee22aa7297daa305cde69b30bc0720f3cf779cf69efa6f42cb"
        )
    }

    func testGETRequest() throws {
        let signer = TCSignerV3(credential: credential, service: "region")
        let headers = try signer.signHeaders(
            url: "https://region.tencentcloudapi.com/?Product=cvm",
            method: .GET,
            headers: [
                "content-type": "application/x-www-form-urlencoded",
                "x-tc-action": "DescribeRegions",
                "x-tc-version": "2022-06-27",
            ],
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/region/tc3_request, SignedHeaders=content-type;host;x-tc-action;x-tc-content-sha256;x-tc-requestclient;x-tc-timestamp;x-tc-version, Signature=96a261572b4f62ec92bd6f94e28dd772987d77927f937c94524f5a6a955cd7d5"
        )
    }

    func testBodyData() throws {
        let string = "testing, testing, 1,2,1,2"
        let data = string.data(using: .utf8)!
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        let signer = TCSignerV3(credential: credential, service: "cvm")
        let headers1 = try signer.signHeaders(url: "https://cvm.tencentcloudapi.com", method: .POST, body: .string(string), date: Date(timeIntervalSinceReferenceDate: 0))
        let headers2 = try signer.signHeaders(url: "https://cvm.tencentcloudapi.com", method: .POST, body: .data(data), date: Date(timeIntervalSinceReferenceDate: 0))
        let headers3 = try signer.signHeaders(url: "https://cvm.tencentcloudapi.com", method: .POST, body: .byteBuffer(buffer), date: Date(timeIntervalSinceReferenceDate: 0))

        XCTAssertNotNil(headers1["authorization"].first)
        XCTAssertEqual(headers1["authorization"].first, headers2["authorization"].first)
        XCTAssertEqual(headers2["authorization"].first, headers3["authorization"].first)
    }

    func testUppercasedHeaderName() throws {
        let signer = TCSignerV3(credential: credential, service: "region")
        let headers = try signer.signHeaders(
            url: "https://region.tencentcloudapi.com",
            method: .POST,
            headers: [
                "Content-Type": "application/json",
                "X-TC-ACTION": "DescribeRegions",
                "X-TC-VERSION": "2022-06-27",
            ],
            body: .string(#"{"Product":"cvm"}"#),
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["Authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/region/tc3_request, SignedHeaders=content-type;host;x-tc-action;x-tc-content-sha256;x-tc-requestclient;x-tc-timestamp;x-tc-version, Signature=2e9e6e2b803969ee22aa7297daa305cde69b30bc0720f3cf779cf69efa6f42cb"
        )
    }

    func testCanonicalRequest() throws {
        let signer = TCSignerV3(credential: credential, service: "sns")
        let signingData = TCSignerV3.SigningData(
            path: "/",
            query: "hello=true&item=apple",
            method: .POST,
            headers: ["content-type": "application/json", "host": "localhost", "User-Agent": "Teco Test"],
            body: .string("{}"),
            timestamp: Date(timeIntervalSince1970: 234_873).timestamp,
            date: TCSignerV3.dateString(Date(timeIntervalSince1970: 234_873)),
            signer: signer
        )
        let request = signer.canonicalRequest(signingData: signingData)
        let expectedRequest = """
        POST
        /
        hello=true&item=apple
        content-type:application/json
        host:localhost

        content-type;host
        44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a
        """
        XCTAssertEqual(request, expectedRequest)
    }

    func testSkipAuthorization() throws {
        let signer = TCSignerV3(credential: credential, service: "cvm")
        let headers = try signer.signHeaders(
            url: "https://cvm.tencentcloudapi.com/?InstanceIds.0=ins-000000",
            method: .GET,
            headers: ["content-type": "application/x-www-form-urlencoded"],
            mode: .skip,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(headers["authorization"].first, "SKIP")
    }

    // MARK: - Tencent Cloud signer examples

    // https://cloud.tencent.com/document/api/213/30654
    func testTencentCloudExample() throws {
        let credential = StaticCredential(secretId: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE", secretKey: "Gu5t9xGARNpq86cd98joQYCN3EXAMPLE")
        let signer = TCSignerV3(credential: credential, service: "cvm")
        let signedHeaders = signer.signHeaders(
            url: URLComponents(string: "https://cvm.tencentcloudapi.com")!,
            method: .POST,
            headers: [
                "content-type": "application/json; charset=utf-8",
                "host": "cvm.tencentcloudapi.com",
                "x-tc-action": "DescribeInstances",
                "x-tc-timestamp": "1551113065",
                "x-tc-version": "2017-03-12",
                "x-tc-region": "ap-guangzhou",
            ],
            body: .string(#"{"Limit": 1, "Filters": [{"Values": ["\u672a\u547d\u540d"], "Name": "instance-name"}]}"#),
            mode: .minimal,
            date: Date(timeIntervalSince1970: 1551113065)
        )
        XCTAssertEqual(
            signedHeaders["authorization"].first,
            "TC3-HMAC-SHA256 Credential=AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE/2019-02-25/cvm/tc3_request, SignedHeaders=content-type;host, Signature=72e494ea809ad7a8c8f7a4507b9bddcbaa8e581f516e8da2f66e2c5a96525168"
        )
    }
}
