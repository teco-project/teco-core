//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
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
// Copyright (c) 2020-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.URL
import Logging
import NIOCore
import NIOHTTP1

/// Tencent Cloud service client protocol.
///
/// Contains a client to communicate with Tencent Cloud and configuration for defining how to communicate.
public protocol TCService: TecoSendable {
    /// Client used to communicate with Tencent Cloud.
    var client: TCClient { get }
    /// Service context details.
    var config: TCServiceConfig { get }

    /// Create new version of service with patch.
    ///
    /// This is required to support ``with(region:language:endpoint:timeout:byteBufferAllocator:)``.
    ///
    /// Standard implementation is as follows:
    /// ```swift
    /// public init(from service: MyService, patch: TCServiceConfig.Patch) {
    ///     self.client = service.client
    ///     self.config = service.config.with(patch: patch)
    /// }
    /// ```
    init(from: Self, patch: TCServiceConfig.Patch)
}

extension TCService {
    /// Default region of the service to operate on.
    public var defaultRegion: TCRegion? { config.region }
    /// Default endpoint URL to use in requests.
    public var defaultEndpoint: String { config.endpoint }
    /// ``EventLoopGroup`` the service is using.
    public var eventLoopGroup: EventLoopGroup { client.eventLoopGroup }

    /// Returns the service endpoint URL.
    public func endpoint(for region: TCRegion? = nil) -> String {
        self.config.getEndpoint(for: region)
    }

    /// Generate signed headers.
    ///
    /// - Parameters:
    ///    - url : URL to sign.
    ///    - httpMethod: HTTP method to use (`POST` by default).
    ///    - headers: Headers that are to be sent with this URL.
    ///    - body: Payload to sign.
    ///    - logger: Logger to output to.
    /// - Returns: A set of signed headers that include the original headers supplied.
    public func signHeaders(
        url: URL,
        httpMethod: HTTPMethod = .POST,
        headers: HTTPHeaders = HTTPHeaders(),
        body: TCPayload = .empty,
        logger: Logger = TCClient.loggingDisabled
    ) -> EventLoopFuture<HTTPHeaders> {
        return self.client.signHeaders(url: url, httpMethod: httpMethod, headers: headers, body: body, serviceConfig: self.config, logger: logger)
    }

    /// Returns a new version of service with edited parameters.
    ///
    /// - Parameters:
    ///   - region: Default region of the service to operate on.
    ///   - language: Preferred language for API response.
    ///   - endpoint: Endpoint provider for API request.
    ///   - timeout: Timeout value for HTTP requests.
    ///   - byteBufferAllocator: Byte buffer allocator used by ``TCClient``.
    /// - Returns: New version of the service.
    public func with(
        region: TCRegion? = nil,
        language: TCServiceConfig.Language? = nil,
        endpoint: EndpointProviderFactory? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator? = nil
    ) -> Self {
        return Self(from: self, patch: .init(
            region: region,
            language: language,
            endpoint: endpoint,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator
        ))
    }
}
