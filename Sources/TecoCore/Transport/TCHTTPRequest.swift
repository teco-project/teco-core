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
@_implementationOnly import MultipartKit
import NIOCore
@_implementationOnly import NIOFoundationCompat
import NIOHTTP1
import TecoSigner

/// Structure encapsulating all the information needed to generate a raw HTTP request to Tencent Cloud.
struct TCHTTPRequest {
    /// Request Tencent Cloud region.
    private let region: TCRegion?
    /// Request URL.
    internal let url: URL
    /// Request HTTP method.
    internal let method: HTTPMethod
    /// Request HTTP headers.
    internal var headers: HTTPHeaders
    /// Request body.
    internal let body: ByteBuffer?

    /// Sign the request headers with given configuration.
    ///
    /// - Parameters:
    ///   - signer: Tencent Cloud API signer to use.
    ///   - mode: Signing mode.
    internal mutating func signHeaders(with signer: TCSignerV3, mode: TCSignerV3.SigningMode) {
        // if credentials are empty don't sign request
        guard mode == .skip || !signer.credential.isEmpty else {
            assertionFailure("Empty credential provided for request!")
            return
        }
        // replace original headers with signed ones
        headers = signer.signHeaders(
            url: url,
            method: method,
            headers: headers,
            body: body.map { .byteBuffer($0) },
            mode: mode
        )
    }
}

extension TCHTTPRequest {
    internal init(action: String, path: String = "/", region: TCRegion? = nil, method: HTTPMethod, service: TCServiceConfig) throws {
        let endpoint = service.getEndpoint(for: region)
        guard let url = URL(string: "\(endpoint)\(path)"), let _ = url.host else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = region ?? service.region
        self.url = url
        self.method = method
        self.headers = HTTPHeaders()
        self.body = nil

        // set common parameter headers
        self.addCommonParameters(action: action, service: service)
        self.addStandardHeaders()
    }

    internal init<Input: TCRequest>(
        action: String,
        path: String = "/",
        region: TCRegion? = nil,
        method: HTTPMethod,
        input: Input,
        service: TCServiceConfig
    ) throws {
        let body = try JSONEncoder().encodeAsByteBuffer(input, allocator: service.byteBufferAllocator)

        let endpoint = service.getEndpoint(for: region)
        guard let url = URL(string: "\(endpoint)\(path)") else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = region ?? service.region
        self.url = url
        self.method = method
        self.headers = HTTPHeaders()
        self.body = body

        // set common parameter headers
        self.addCommonParameters(action: action, service: service)
        self.addStandardHeaders()
    }

    internal init<Input: TCMultipartRequest>(
        action: String,
        path: String = "/",
        region: TCRegion? = nil,
        method: HTTPMethod,
        input: Input,
        service: TCServiceConfig
    ) throws {
        let body = try FormDataEncoder().encodeAsByteBuffer(input, allocator: service.byteBufferAllocator)

        let endpoint = service.getEndpoint(for: region)
        guard let url = URL(string: "\(endpoint)\(path)") else {
            throw TCClient.ClientError.invalidURL
        }

        self.region = region ?? service.region
        self.url = url
        self.method = method
        self.headers = HTTPHeaders()
        self.body = body

        // set common parameter headers
        self.addCommonParameters(action: action, service: service)
        self.addStandardHeaders(contentType: "multipart/form-data")
    }

    /// Add common header parameters to all requests: "Action", "Version", "Region" and "Language".
    private mutating func addCommonParameters(action: String, service: TCServiceConfig) {
        headers.replaceOrAdd(name: "x-tc-action", value: action)
        headers.replaceOrAdd(name: "x-tc-version", value: service.version)
        if let region = self.region {
            headers.replaceOrAdd(name: "x-tc-region", value: region.rawValue)
        }
        if let language = service.language {
            headers.replaceOrAdd(name: "x-tc-language", value: language.rawValue)
        }
    }

    /// Add headers standard to all requests: "content-type" and "user-agent".
    private mutating func addStandardHeaders(contentType: String? = nil) {
        headers.add(name: "user-agent", value: "Teco/0.1")

        switch (method, contentType) {
        case (_, .some(let contentType)):
            headers.replaceOrAdd(name: "content-type", value: contentType)
        case (.GET, _):
            headers.replaceOrAdd(name: "content-type", value: "application/x-www-form-urlencoded")
        case (.POST, _):
            headers.replaceOrAdd(name: "content-type", value: "application/json")
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

extension FormDataEncoder {
    /// Writes a Multipart Form Data representation of the value you supply into a `ByteBuffer` that is freshly allocated.
    ///
    /// - Parameters:
    ///   - value: The value to encode as Multipart.
    ///   - nonce: One-time boundary suffix. Defaults to generate randomly.
    ///   - allocator: The `ByteBufferAllocator` which is used to allocate the `ByteBuffer` to be returned.
    /// - Returns: The `ByteBuffer` containing the encoded form data.
    fileprivate func encodeAsByteBuffer<T: Encodable>(_ value: T, nonce: String? = nil, allocator: ByteBufferAllocator) throws -> ByteBuffer {
        let nonce = nonce ?? {
            String((0..<6).compactMap({ _ in "0123456789abcdef".randomElement() }))
        }()
        var buffer = allocator.buffer(capacity: 0)
        try self.encode(value, boundary: "teco-\(nonce)", into: &buffer)
        return buffer
    }
}
