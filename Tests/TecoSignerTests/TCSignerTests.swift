//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Teco project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
@testable import TecoSigner
import XCTest

@propertyWrapper struct EnvironmentVariable<Value: LosslessStringConvertible> {
    var defaultValue: Value
    var variableName: String

    public init(_ variableName: String, default: Value) {
        self.defaultValue = `default`
        self.variableName = variableName
    }

    public var wrappedValue: Value {
        guard let value = ProcessInfo.processInfo.environment[variableName] else { return self.defaultValue }
        return Value(value) ?? self.defaultValue
    }
}

final class TCSignerTests: XCTestCase {
    @EnvironmentVariable("ENABLE_TIMING_TESTS", default: true) static var enableTimingTests: Bool
    let credential: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY")
    let credentialWithSessionToken: Credential = StaticCredential(secretId: "MY_TC_SECRET_ID", secretKey: "MY_TC_SECRET_KEY", token: "MY_TC_SESSION_TOKEN")
    let tcSampleCredential: Credential = StaticCredential(secretId: "AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE", secretKey: "Gu5t9xGARNpq86cd98joQYCN3EXAMPLE")
    let tcSampleDate: Date = Date(timeIntervalSince1970: 1551113065)

    // - MARK: Basic signing by API Explorer - https://console.cloud.tencent.com/api/explorer

    func testBasicSignPostRequest() {
        let signer = TCSigner(credential: credential, service: "cvm", version: "2017-03-12")
        let headers = signer.signHeaders(
            url: URL(string: "https://cvm.tencentcloudapi.com")!,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: .string("{}"),
            basicSigning: true,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["Authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/cvm/tc3_request, SignedHeaders=content-type;host, Signature=2c0b761dcdeacac29ac9d135f9f22b0fa52d4536d8b7727a8a515935c47eaea7"
        )
    }

    func testBasicSignGetRequest() {
        let signer = TCSigner(credential: credential, service: "cvm", version: "2017-03-12")
        let headers = signer.signHeaders(
            url: URL(string: "https://cvm.tencentcloudapi.com/?InstanceIds.0=ins-000000&InstanceIds.1=ins-000001")!,
            method: .GET,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            basicSigning: true,
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["Authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/cvm/tc3_request, SignedHeaders=content-type;host, Signature=a4315b91798a181a6e5fb0353590040a399edad4a003ef5688d71fb34366c471"
        )
    }

    // - MARK: Extended Signing
    
    func testSignPostRequest() {
        let signer = TCSigner(credential: credential, service: "region", version: "2022-06-27")
        let headers = signer.signHeaders(
            url: URL(string: "https://region.tencentcloudapi.com")!,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: .string(#"{"Product":"cvm"}"#),
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["Authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/region/tc3_request, SignedHeaders=content-type;host;x-tc-content-sha256;x-tc-requestclient;x-tc-timestamp;x-tc-version, Signature=feec021ffbf7fdd7adcf734f81d665f6f4946fdfdb9d04a316bfa08901472f18"
        )
    }

    func testSignGetRequest() {
        let signer = TCSigner(credential: credential, service: "region", version: "2022-06-27")
        let headers = signer.signHeaders(
            url: URL(string: "https://region.tencentcloudapi.com/?Product=cvm")!,
            method: .GET,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            date: Date(timeIntervalSince1970: 1_000_000_000)
        )
        XCTAssertEqual(
            headers["Authorization"].first,
            "TC3-HMAC-SHA256 Credential=MY_TC_SECRET_ID/2001-09-09/region/tc3_request, SignedHeaders=content-type;host;x-tc-content-sha256;x-tc-requestclient;x-tc-timestamp;x-tc-version, Signature=dd2225a8938211951f43af1928df59f3496cfcc9eaac9a67a290e87732aedc44"
        )
    }

    func testBodyData() {
        let string = "testing, testing, 1,2,1,2"
        let data = string.data(using: .utf8)!
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        let signer = TCSigner(credential: credential, service: "cvm", version: "2017-03-12")
        let headers1 = signer.signHeaders(url: URL(string: "https://cvm.tencentcloudapi.com")!, method: .POST, body: .string(string), date: Date(timeIntervalSinceReferenceDate: 0))
        let headers2 = signer.signHeaders(url: URL(string: "https://cvm.tencentcloudapi.com")!, method: .POST, body: .data(data), date: Date(timeIntervalSinceReferenceDate: 0))
        let headers3 = signer.signHeaders(url: URL(string: "https://cvm.tencentcloudapi.com")!, method: .POST, body: .byteBuffer(buffer), date: Date(timeIntervalSinceReferenceDate: 0))

        XCTAssertNotNil(headers1["Authorization"].first)
        XCTAssertEqual(headers1["Authorization"].first, headers2["Authorization"].first)
        XCTAssertEqual(headers2["Authorization"].first, headers3["Authorization"].first)
    }

    func testCanonicalRequest() throws {
        let url = URL(string: "https://test.com/?hello=true&item=apple")!
        let signer = TCSigner(credential: credential, service: "sns", version: "2020-01-01")
        let signingData = TCSigner.SigningData(
            url: url,
            method: .POST,
            headers: ["Content-Type": "application/json", "Host": "localhost", "User-Agent": "Teco Test"],
            body: .string("{}"),
            timestamp: TCSigner.timestamp(Date(timeIntervalSince1970: 234_873)),
            date: TCSigner.dateString(Date(timeIntervalSince1970: 234_873)),
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

    // MARK: - Tencent Cloud Signer samples

    // https://cloud.tencent.com/document/api/213/30654
    func testTCSample() {
        let signer = TCSigner(credential: tcSampleCredential, service: "cvm", version: "2017-03-12")
        let url = URL(string: "https://cvm.tencentcloudapi.com")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json; charset=utf-8",
            "Host": "cvm.tencentcloudapi.com",
            "X-TC-Action": "DescribeInstances",
            "X-TC-Timestamp": "1551113065",
            "X-TC-Version": "2017-03-12",
            "X-TC-Region": "ap-guangzhou",
        ]
        let body: TCSigner.BodyData = .string(#"{"Limit": 1, "Filters": [{"Values": ["\u672a\u547d\u540d"], "Name": "instance-name"}]}"#)
        let signedHeaders = signer.signHeaders(
            url: url, method: .POST, headers: headers, body: body, basicSigning: true, date: tcSampleDate
        )
        XCTAssertEqual(
            signedHeaders["Authorization"].first,
            "TC3-HMAC-SHA256 Credential=AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE/2019-02-25/cvm/tc3_request, SignedHeaders=content-type;host, Signature=72e494ea809ad7a8c8f7a4507b9bddcbaa8e581f516e8da2f66e2c5a96525168"
        )
    }
}
