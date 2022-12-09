//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// This source file was part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.URL
import struct Foundation.URLComponents
import NIOCore
import NIOHTTP1
import TecoSigner

/// Object encapsulating all the information needed to generate a raw HTTP request to Tencent Cloud.
public struct TCRequest {
    /// request Tencent Cloud region
    public let region: TCRegion
    /// request URL
    public var url: URL
    /// request HTTP method
    public let httpMethod: HTTPMethod
    /// request headers
    public var httpHeaders: HTTPHeaders
    /// request body
    public var body: Body

    /// Create HTTP Client request from TCRequest.
    /// If the signer's credentials are available the request will be signed. Otherwise defaults to an unsigned request
    func createHTTPRequest(signer: TCSigner, serviceConfig: TCServiceConfig) -> TCHTTPRequest {
        // if credentials are empty don't sign request
        if signer.credential.isEmpty() {
            return self.toHTTPRequest(byteBufferAllocator: serviceConfig.byteBufferAllocator)
        }

        return self.toHTTPRequestWithSignedHeader(signer: signer, serviceConfig: serviceConfig)
    }

    /// Create HTTP Client request from TCRequest
    func toHTTPRequest(byteBufferAllocator: ByteBufferAllocator) -> TCHTTPRequest {
        return TCHTTPRequest(url: url, method: httpMethod, headers: httpHeaders, body: body.asPayload(byteBufferAllocator: byteBufferAllocator))
    }

    /// Create HTTP Client request with signed headers from TCRequest
    func toHTTPRequestWithSignedHeader(signer: TCSigner, serviceConfig: TCServiceConfig) -> TCHTTPRequest {
        let payload = self.body.asPayload(byteBufferAllocator: serviceConfig.byteBufferAllocator)
        let bodyDataForSigning: TCSigner.BodyData?
        switch payload.payload {
        case .byteBuffer(let buffer):
            bodyDataForSigning = .byteBuffer(buffer)
        case .empty:
            bodyDataForSigning = nil
        }
        let signedHeaders = signer.signHeaders(url: url, method: httpMethod, headers: httpHeaders, body: bodyDataForSigning, date: Date())
        return TCHTTPRequest(url: url, method: httpMethod, headers: signedHeaders, body: payload)
    }
}

extension TCRequest {
    internal init(action: String, path: String = "/", httpMethod: HTTPMethod, configuration: TCServiceConfig) throws {
        guard let url = URL(string: "\(configuration.endpoint)\(path)"), let _ = url.host else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = configuration.region
        self.url = url
        self.httpMethod = httpMethod
        self.httpHeaders = HTTPHeaders()
        self.body = .empty

        // set common parameter headers
        self.addCommonParameters(action: action, configuration: configuration)
        self.addStandardHeaders()
    }

    internal init<Input: TCEncodableData>(
        action: String,
        path: String = "/",
        httpMethod: HTTPMethod,
        input: Input,
        configuration: TCServiceConfig
    ) throws {
        let body = try input.encodeAsJSON(byteBufferAllocator: configuration.byteBufferAllocator)

        guard let urlComponents = URLComponents(string: "\(configuration.endpoint)\(path)"),
              let url = urlComponents.url else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = configuration.region
        self.url = url
        self.httpMethod = httpMethod
        self.httpHeaders = HTTPHeaders()
        self.body = .json(body)

        // set common parameter headers
        self.addCommonParameters(action: action, configuration: configuration)
        self.addStandardHeaders()
    }
    
    /// Add common header parameters to all requests "Action", "Version" and "Language".
    private mutating func addCommonParameters(action actionName: String, configuration: TCServiceConfig) {
        httpHeaders.replaceOrAdd(name: "X-TC-Action", value: actionName)
        httpHeaders.replaceOrAdd(name: "X-TC-Version", value: configuration.apiVersion)
        if let language = configuration.language {
            httpHeaders.replaceOrAdd(name: "X-TC-Language", value: language.rawValue)
        }
    }

    /// Add headers standard to all requests "content-type" and "user-agent"
    private mutating func addStandardHeaders() {
        httpHeaders.add(name: "user-agent", value: "Teco/0.1")

        switch httpMethod {
        case .GET:
            httpHeaders.replaceOrAdd(name: "Content-Type", value: "application/x-www-form-urlencoded")
        case .POST:
            httpHeaders.replaceOrAdd(name: "content-type", value: "application/json")
        default:
            return
        }
    }
}
