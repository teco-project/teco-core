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

import NIOCore
import struct Foundation.URL

/// Configuration that defines a Tencent Cloud service.
public struct TCServiceConfig: Sendable {
    /// Region where service is running.
    public let region: TCRegion
    /// Short name of the service.
    public let service: String
    /// Version of the service API.
    public let apiVersion: String
    /// Preferred language for API response.
    public let language: Language?
    /// The endpoint URL to use in requests.
    public let endpoint: String
    /// The base error type returned by the service
    public let errorType: TCErrorType.Type?
    /// timeout value for HTTP requests
    public let timeout: TimeAmount
    /// ByteBuffer allocator used by service
    public let byteBufferAllocator: ByteBufferAllocator
    /// A provider to generate endpoint for service.
    private let endpointProvider: Endpoint

    /// Create a ``TCServiceConfig`` configuration.
    ///
    /// - Parameters:
    ///   - region: Region of the service you want to operate on.
    ///   - service: Name of the service endpoint.
    ///   - apiVersion: Service API version.
    ///   - language: Preferred language for API response.
    ///   - endpoint: Endpoint URL for API request.
    ///   - errorType: Base error type that the client may throw.
    ///   - timeout: Time out value for HTTP requests.
    ///   - byteBufferAllocator: Byte buffer allocator used throughout ``TCClient``.
    public init(
        region: TCRegion?,
        service: String,
        apiVersion: String,
        language: Language? = nil,
        endpoint: Endpoint = .global,
        errorType: TCErrorType.Type? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()
    ) {
        if let region = region {
            self.region = region
        } else if let defaultRegion = Environment["TENCENTCLOUD_REGION"] {
            self.region = TCRegion(id: defaultRegion)
        } else {
            self.region = .ap_guangzhou
        }
        self.service = service
        self.apiVersion = apiVersion
        self.language = language
        self.errorType = errorType
        self.timeout = timeout ?? .seconds(20)
        self.byteBufferAllocator = byteBufferAllocator

        self.endpointProvider = endpoint
        self.endpoint = endpoint.resolve(region: self.region, service: service)
    }

    /// Languges supported by Tencent Cloud services.
    public enum Language: String, Sendable, Equatable {
        case zh_CN = "zh-CN"
        case en_US = "en-US"
    }

    /// Endpoint configuration for the Tencent Cloud service.
    public enum Endpoint: Sendable, Equatable {
        /// Prefers to use the endpoint of service region (eg. https://cvm.ap-guangzhou.tencentcloudapi.com ).
        case service
        /// Prefers to use the global endpoint (eg. https://cvm.tencentcloudapi.com ).
        case global
        /// Prefers to use the endpoint of specific region (eg. https://cvm.ap-guangzhou.tencentcloudapi.com ).
        case regional(TCRegion)
        /// Provides a custom endpoint.
        case custom(url: String)

        fileprivate static let baseDomain = "tencentcloudapi.com"

        fileprivate func resolve(region: TCRegion, service: String) -> String {
            switch self {
            case .custom(let endpoint):
                return endpoint
            case .regional(let customRegion):
                return "https://\(service).\(customRegion.rawValue).\(Self.baseDomain)"
            case .global where region.kind == .global:
                return "https://\(service).\(Self.baseDomain)"
            default:
                return "https://\(service).\(region.rawValue).\(Self.baseDomain)"
            }
        }
    }

    /// Return a new version of service configuration with edited parameters.
    ///
    /// - Parameters:
    ///   - patch: Parameters to patch the service config.
    ///
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
        if let region = patch.region {
            self.region = region
            self.endpoint = (patch.endpoint ?? service.endpointProvider).resolve(region: region, service: service.service)
        } else {
            self.region = service.region
            self.endpoint = patch.endpoint?.resolve(region: region, service: service.service) ?? service.endpoint
        }
        self.service = service.service
        self.apiVersion = service.apiVersion
        self.language = patch.language ?? service.language
        self.endpointProvider = service.endpointProvider
        self.errorType = service.errorType
        self.timeout = patch.timeout ?? service.timeout
        self.byteBufferAllocator = patch.byteBufferAllocator ?? service.byteBufferAllocator
    }
}

extension TCServiceConfig.Endpoint: LosslessStringConvertible {
    /// Create a `TCServiceConfig.Endpoint` from URL string.
    ///
    /// - Parameter url: The endpoint URL string.
    public init?(_ url: String) {
        guard let url = URL(string: url), url.scheme == "http" || url.scheme == "https" else {
            return nil
        }
        self = .custom(url: url.standardized.absoluteString)
    }

    public var description: String {
        switch self {
        case .service:
            return "https://<service>.<region>.\(Self.baseDomain)"
        case .global:
            return "https://<service>.\(Self.baseDomain)"
        case .regional(let region):
            return "https://<service>.\(region).\(Self.baseDomain)"
        case .custom(let url):
            return url
        }
    }
}
