//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2022 the Teco project authors
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

/// Services client protocol. Contains a client to communicate with Tencent Cloud and configuration for defining how to communicate.
public protocol TCService: TecoSendable {
    /// Client used to communicate with Tencent Cloud
    var client: TCClient { get }
    /// Service context details
    var config: TCServiceConfig { get }
    /// Create new version of service with patch
    ///
    /// This is required to support ``with(region:language:timeout:byteBufferAllocator:)``.
    /// Standard implementation is as follows
    /// ```swift
    /// public init(from: MyService, patch: TCServiceConfig.Patch) {
    ///     self.client = from.client
    ///     self.config = from.config.with(patch: patch)
    /// }
    /// ```
    init(from: Self, patch: TCServiceConfig.Patch)
}

extension TCService {
    /// Region where service is running
    public var region: TCRegion { return config.region }
    /// The url to use in requests
    public var endpoint: String { return config.endpoint }
    /// The EventLoopGroup service is using
    public var eventLoopGroup: EventLoopGroup { return client.eventLoopGroup }

    /// Generate signed headers
    /// - parameters:
    ///     - url : URL to sign
    ///     - httpMethod: HTTP method to use (.GET or .POST)
    ///     - headers: Headers that are to be used with this URL. Be sure to include these headers when you used the returned URL
    ///     - body: body payload to sign as well. While it is unnecessary to provide the body for S3 other services require it
    ///     - logger: Logger to output to
    /// - returns:
    ///     A series of signed headers including the original headers provided to the function
    public func signHeaders(
        url: URL,
        httpMethod: HTTPMethod = .POST,
        headers: HTTPHeaders = HTTPHeaders(),
        body: TCPayload = .empty,
        logger: Logger = TCClient.loggingDisabled
    ) -> EventLoopFuture<HTTPHeaders> {
        return self.client.signHeaders(url: url, httpMethod: httpMethod, headers: headers, body: body, serviceConfig: self.config, logger: logger)
    }

    /// Return new version of Service with edited parameters
    /// - Parameters:
    ///   - region: Server region
    ///   - language: Language preference
    ///   - timeout: Time out value for HTTP requests
    ///   - byteBufferAllocator: Byte buffer allocator used throughout TCClient
    /// - Returns: New version of the service
    public func with(
        region: TCRegion? = nil,
        language: TCServiceConfig.Language? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator? = nil
    ) -> Self {
        return Self(from: self, patch: .init(
            region: region,
            language: language,
            timeout: timeout,
            byteBufferAllocator: byteBufferAllocator
        ))
    }
}
