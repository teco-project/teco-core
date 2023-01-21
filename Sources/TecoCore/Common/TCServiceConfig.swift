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
    private let defaultEndpoint: String
    /// Provider that generates endpoint URL for service.
    private let endpointProvider: EndpointProvider
    /// The base error type returned by the service.
    public let errorType: TCErrorType.Type?
    /// Timeout value for HTTP requests.
    public let timeout: TimeAmount
    /// Byte buffer allocator used by service.
    public let byteBufferAllocator: ByteBufferAllocator

    /// Create a ``TCServiceConfig`` configuration.
    ///
    /// - Parameters:
    ///   - service: Name of the service endpoint.
    ///   - version: Service API version.
    ///   - region: Default region of the service to operate on.
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
        self.endpointProvider = endpoint.endpointProvider
        self.defaultEndpoint = self.endpointProvider.getEndpoint(for: service, region: self.region)

        self.service = service
        self.version = version
        self.language = language
        self.errorType = errorType
        self.timeout = timeout ?? .seconds(20)
        self.byteBufferAllocator = byteBufferAllocator
    }

    /// Languges supported by Tencent Cloud services.
    public enum Language: String, Sendable, Equatable {
        case zh_CN = "zh-CN"
        case en_US = "en-US"
    }

    /// Endpoint provider for Tencent Cloud APIs.
    public typealias Endpoint = EndpointProviderFactory

    /// Returns the endpoint URL for provided region.
    public func getEndpoint(for region: TCRegion? = nil) -> String {
        if let region = region {
            return self.endpointProvider.getEndpoint(for: self.service, region: region)
        } else {
            return self.defaultEndpoint
        }
    }

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
        let endpointProvider: EndpointProvider?
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
            self.endpointProvider = endpoint?.endpointProvider
            self.timeout = timeout
            self.byteBufferAllocator = byteBufferAllocator
        }
    }

    private init(service: TCServiceConfig, with patch: Patch) {
        // try to short-circuit endpoint resolution as it may be expensive
        if let region = patch.region {
            self.region = region
            self.endpointProvider = patch.endpointProvider ?? service.endpointProvider
            self.defaultEndpoint = self.endpointProvider.getEndpoint(for: service.service, region: self.region)
        } else {
            self.region = service.region
            if let endpointProvider = patch.endpointProvider {
                self.endpointProvider = endpointProvider
                self.defaultEndpoint = endpointProvider.getEndpoint(for: service.service, region: self.region)
            } else {
                self.endpointProvider = service.endpointProvider
                self.defaultEndpoint = service.defaultEndpoint
            }
        }

        self.service = service.service
        self.version = service.version
        self.language = patch.language ?? service.language
        self.errorType = service.errorType
        self.timeout = patch.timeout ?? service.timeout
        self.byteBufferAllocator = patch.byteBufferAllocator ?? service.byteBufferAllocator
    }
}
