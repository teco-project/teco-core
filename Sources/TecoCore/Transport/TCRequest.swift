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
import class Foundation.JSONEncoder
import struct Foundation.URL
import struct Foundation.URLComponents
import NIOCore
import NIOFoundationCompat
import NIOHTTP1
import TecoSigner

/// Structure encapsulating all the information needed to generate a raw HTTP request to Tencent Cloud.
struct TCRequest {
    /// Request Tencent Cloud region.
    private let region: TCRegion?
    /// Request URL.
    internal let url: URL
    /// Request HTTP method.
    internal let httpMethod: HTTPMethod
    /// Request HTTP headers.
    internal var httpHeaders: HTTPHeaders
    /// Request body.
    internal let body: ByteBuffer?

    /// Sign the request headers with given configuration.
    ///
    /// - Parameters:
    ///   - signer: Tencent Cloud API signer to use.
    ///   - signingMode: Signing mode.
    internal mutating func signHeaders(with signer: TCSigner, signingMode: TCSigner.SigningMode) {
        // if credentials are empty don't sign request
        guard signingMode == .skip || !signer.credential.isEmpty else {
            assertionFailure("Empty credential provided for request!")
            return
        }
        // replace original headers with signed ones
        httpHeaders = signer.signHeaders(
            url: url,
            method: httpMethod,
            headers: httpHeaders,
            body: body.map { .byteBuffer($0) },
            mode: signingMode
        )
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
        self.body = nil

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
        let body = try JSONEncoder().encodeAsByteBuffer(input, allocator: configuration.byteBufferAllocator)

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
        self.body = body

        // set common parameter headers
        self.addCommonParameters(action: action, configuration: configuration)
        self.addStandardHeaders()
    }

    /// Add common header parameters to all requests: "Action", "Version", "Region" and "Language".
    private mutating func addCommonParameters(action: String, configuration: TCServiceConfig) {
        httpHeaders.replaceOrAdd(name: "x-tc-action", value: action)
        httpHeaders.replaceOrAdd(name: "x-tc-version", value: configuration.version)
        if let region = self.region {
            httpHeaders.replaceOrAdd(name: "x-tc-region", value: region.rawValue)
        }
        if let language = configuration.language {
            httpHeaders.replaceOrAdd(name: "x-tc-language", value: language.rawValue)
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
