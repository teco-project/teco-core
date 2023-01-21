//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022-2023 the Teco project authors
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

/// Structure encapsulating all the information needed to generate a raw HTTP request to Tencent Cloud.
struct TCRequest {
    /// Request Tencent Cloud region.
    private let region: TCRegion?
    /// Request URL.
    private let url: URL
    /// Request HTTP method.
    private let httpMethod: HTTPMethod
    /// Request HTTP headers.
    private var httpHeaders: HTTPHeaders
    /// Request body.
    private let body: Body

    /// Create HTTP Client request from ``TCRequest``.
    ///
    /// If the signer's credentials are available the request will be signed. Otherwise defaults to an unsigned request.
    internal func createHTTPRequest(signer: TCSigner, serviceConfig: TCServiceConfig, signingMode: TCSigner.SigningMode) -> TCHTTPRequest {
        // if credentials are empty don't sign request
        if signingMode != .skip && signer.credential.isEmpty {
            return self.toHTTPRequest(byteBufferAllocator: serviceConfig.byteBufferAllocator)
        }

        return self.toHTTPRequestWithSignedHeader(signer: signer, serviceConfig: serviceConfig, signingMode: signingMode)
    }

    /// Create HTTP Client request from ``TCRequest``.
    private func toHTTPRequest(byteBufferAllocator: ByteBufferAllocator) -> TCHTTPRequest {
        return TCHTTPRequest(url: url, method: httpMethod, headers: httpHeaders, body: body.asPayload(byteBufferAllocator: byteBufferAllocator))
    }

    /// Create HTTP Client request with signed headers from ``TCRequest``.
    private func toHTTPRequestWithSignedHeader(signer: TCSigner, serviceConfig: TCServiceConfig, signingMode: TCSigner.SigningMode) -> TCHTTPRequest {
        let payload = self.body.asPayload(byteBufferAllocator: serviceConfig.byteBufferAllocator)
        let bodyDataForSigning: TCSigner.BodyData?
        switch payload.payload {
        case .byteBuffer(let buffer):
            bodyDataForSigning = .byteBuffer(buffer)
        case .empty:
            bodyDataForSigning = nil
        }
        let signedHeaders = signer.signHeaders(url: url, method: httpMethod, headers: httpHeaders, body: bodyDataForSigning, mode: signingMode, date: Date())
        return TCHTTPRequest(url: url, method: httpMethod, headers: signedHeaders, body: payload)
    }
}

extension TCRequest {
    internal init(action: String, path: String = "/", region: TCRegion? = nil, httpMethod: HTTPMethod, configuration: TCServiceConfig) throws {
        let endpoint = configuration.getEndpoint(for: region)
        guard let url = URL(string: "\(endpoint)\(path)"), let _ = url.host else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = region ?? configuration.region
        self.url = url
        self.httpMethod = httpMethod
        self.httpHeaders = HTTPHeaders()
        self.body = .empty

        // set common parameter headers
        self.addCommonParameters(action: action, configuration: configuration)
        self.addStandardHeaders()
    }

    internal init<Input: TCInputModel>(
        action: String,
        path: String = "/",
        region: TCRegion? = nil,
        httpMethod: HTTPMethod,
        input: Input,
        configuration: TCServiceConfig
    ) throws {
        let body = try input.encodeAsJSON(byteBufferAllocator: configuration.byteBufferAllocator)

        let endpoint = configuration.getEndpoint(for: region)
        guard let urlComponents = URLComponents(string: "\(endpoint)\(path)"),
              let url = urlComponents.url
        else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = region ?? configuration.region
        self.url = url
        self.httpMethod = httpMethod
        self.httpHeaders = HTTPHeaders()
        self.body = .json(body)

        // set common parameter headers
        self.addCommonParameters(action: action, configuration: configuration)
        self.addStandardHeaders()
    }

    /// Add common header parameters to all requests: "Action", "Version", "Region" and "Language".
    private mutating func addCommonParameters(action: String, configuration: TCServiceConfig) {
        httpHeaders.replaceOrAdd(name: "X-TC-Action", value: action)
        httpHeaders.replaceOrAdd(name: "X-TC-Version", value: configuration.version)
        if let region = self.region {
            httpHeaders.replaceOrAdd(name: "X-TC-Region", value: region.rawValue)
        }
        if let language = configuration.language {
            httpHeaders.replaceOrAdd(name: "X-TC-Language", value: language.rawValue)
        }
    }

    /// Add headers standard to all requests: "content-type" and "user-agent".
    private mutating func addStandardHeaders() {
        httpHeaders.add(name: "user-agent", value: "Teco/0.1")

        switch httpMethod {
        case .GET:
            httpHeaders.replaceOrAdd(name: "content-type", value: "application/x-www-form-urlencoded")
        case .POST:
            httpHeaders.replaceOrAdd(name: "content-type", value: "application/json")
        default:
            return
        }
    }
}

extension Credential {
    fileprivate var isEmpty: Bool {
        self.secretId.isEmpty || self.secretKey.isEmpty
    }
}
