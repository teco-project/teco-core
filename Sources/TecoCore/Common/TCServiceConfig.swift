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

import NIOCore

/// Configuration that defines a Tencent Cloud service.
public struct TCServiceConfig: Sendable {
    /// Short name of the service.
    public let service: String
    /// Version of the service API.
    public let version: String
    /// Default region of the service to operate on.
    public let region: TCRegion?
    /// Preferred language for API response.
    public let language: Language?
    /// Default endpoint URL to use in requests.
    public let endpoint: String
    /// The base error type returned by the service.
    public let errorType: TCErrorType.Type?
    /// Timeout value for HTTP requests.
    public let timeout: TimeAmount
    /// Byte buffer allocator used by service.
    public let byteBufferAllocator: ByteBufferAllocator

    /// A provider to generate endpoint URL for service.
    private let endpointProvider: Endpoint

    /// Create a ``TCServiceConfig`` configuration.
    ///
    /// - Parameters:
    ///   - service: Name of the service endpoint.
    ///   - version: Service API version.
    ///   - region: Region of the service you want to operate on.
    ///   - language: Preferred language for API response.
    ///   - endpoint: Endpoint provider for API request.
    ///   - errorType: Base error type that the client may throw.
    ///   - timeout: Time out value for HTTP requests.
    ///   - byteBufferAllocator: Byte buffer allocator used throughout ``TCClient``.
    public init(
        service: String,
        version: String,
        region: TCRegion? = nil,
        language: Language? = nil,
        endpoint: Endpoint = .global,
        errorType: TCErrorType.Type? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()
    ) {
        if let region = region {
            self.region = region
        } else if let regionId = Environment["TENCENTCLOUD_REGION"] {
            self.region = TCRegion(id: regionId)
        } else {
            self.region = nil
        }
        self.service = service
        self.version = version
        self.language = language
        self.errorType = errorType
        self.timeout = timeout ?? .seconds(20)
        self.byteBufferAllocator = byteBufferAllocator

        self.endpointProvider = endpoint
        self.endpoint = endpoint.getEndpoint(for: service, region: self.region)
    }

    /// Languges supported by Tencent Cloud services.
    public enum Language: String, Sendable, Equatable {
        case zh_CN = "zh-CN"
        case en_US = "en-US"
    }

    /// Endpoint provider for the Tencent Cloud service.
    public typealias Endpoint = TCServiceEndpointProvider

    /// Returns a new version of service configuration with edited parameters.
    ///
    /// - Parameters:
    ///   - patch: Parameters to patch the service config.
    /// - Returns: A patched ``TCServiceConfig``.
    public func with(patch: Patch) -> TCServiceConfig {
        return TCServiceConfig(service: self, with: patch)
    }

    /// Service config parameters that a user can patch.
    public struct Patch {
        let region: TCRegion?
        let language: TCServiceConfig.Language?
        let endpoint: TCServiceConfig.Endpoint?
        let timeout: TimeAmount?
        let byteBufferAllocator: ByteBufferAllocator?

        init(
            region: TCRegion? = nil,
            language: TCServiceConfig.Language? = nil,
            endpoint: TCServiceConfig.Endpoint? = nil,
            timeout: TimeAmount? = nil,
            byteBufferAllocator: ByteBufferAllocator? = nil
        ) {
            self.region = region
            self.language = language
            self.endpoint = endpoint
            self.timeout = timeout
            self.byteBufferAllocator = byteBufferAllocator
        }
    }

    private init(service: TCServiceConfig, with patch: Patch) {
        if service.region != patch.region, let region = patch.region {
            self.region = region
            self.endpoint = (patch.endpoint ?? service.endpointProvider).getEndpoint(for: service.service, region: region)
        } else {
            self.region = service.region
            self.endpoint = patch.endpoint?.getEndpoint(for: service.service, region: region) ?? service.endpoint
        }
        self.service = service.service
        self.version = service.version
        self.language = patch.language ?? service.language
        self.endpointProvider = service.endpointProvider
        self.errorType = service.errorType
        self.timeout = patch.timeout ?? service.timeout
        self.byteBufferAllocator = patch.byteBufferAllocator ?? service.byteBufferAllocator
    }
}
