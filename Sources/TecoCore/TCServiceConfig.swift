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

/// Configuration struct defining a Tencent Cloud service
public struct TCServiceConfig: Sendable {
    /// Region where service is running
    public let region: TCRegion
    /// Name of service
    public let service: String
    /// Version of the service API
    public let apiVersion: String
    /// Preferred language for API response
    public let language: Language?
    /// The url to use in requests
    public let endpoint: String
    /// The base error type returned by the service
    public let errorType: TCErrorType.Type?
    /// timeout value for HTTP requests
    public let timeout: TimeAmount
    /// ByteBuffer allocator used by service
    public let byteBufferAllocator: ByteBufferAllocator
    /// values used to create endpoint
    private let endpointPreference: EndpointPreference

    /// Create a ServiceConfig object
    ///
    /// - Parameters:
    ///   - region: Region of service you want to operate on
    ///   - service: Name of service endpoint
    ///   - apiVersion: Service API version
    ///   - language: Language of API response
    ///   - endpoint: Endpoint URL preference
    ///   - errorType: Base error type that the client may throw
    ///   - timeout: Time out value for HTTP requests
    ///   - byteBufferAllocator: byte buffer allocator used throughout TCClient
    ///
    public init(
        region: TCRegion?,
        service: String,
        apiVersion: String,
        language: Language? = nil,
        endpoint: EndpointPreference = .global,
        errorType: TCErrorType.Type? = nil,
        timeout: TimeAmount? = nil,
        byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()
    ) {
        if let region = region {
            self.region = region
        } else if let defaultRegion = Environment["TENCENTCLOUD_REGION"] {
            self.region = TCRegion(rawValue: defaultRegion)
        } else {
            self.region = .ap_guangzhou
        }
        self.service = service
        self.apiVersion = apiVersion
        self.language = language
        self.errorType = errorType
        self.timeout = timeout ?? .seconds(20)
        self.byteBufferAllocator = byteBufferAllocator

        self.endpointPreference = endpoint
        self.endpoint = endpoint.resolve(region: self.region, service: service)
    }

    public enum Language: String, Sendable, Equatable {
        case zh_CN = "zh-CN"
        case en_US = "en-US"
    }

    public enum EndpointPreference: Sendable, Equatable {
        /// Prefers to use regional endpoint (eg. https://cvm.ap-guangzhou.tenentcloudapi.com )
        case regional
        /// Prefers to use global endpoint (eg. https://cvm.tenentcloudapi.com )
        case global
        /// Use custom endpoint.
        case custom(_ url: String)

        fileprivate func resolve(region: TCRegion, service: String) -> String {
            switch self {
            case .custom(let endpoint):
                return endpoint
            default:
                return "https://\(service).\(region.hostname(for: service, preferringRegional: self == .regional))"
            }
        }
    }

    /// Return new version of serviceConfig with a modified parameters
    /// - Parameters:
    ///   - patch: parameters to patch service config
    /// - Returns: New TCServiceConfig
    public func with(patch: Patch) -> TCServiceConfig {
        return TCServiceConfig(service: self, with: patch)
    }

    /// Service config parameters you can patch
    public struct Patch {
        let region: TCRegion?
        let language: TCServiceConfig.Language?
        let endpoint: TCServiceConfig.EndpointPreference?
        let timeout: TimeAmount?
        let byteBufferAllocator: ByteBufferAllocator?

        init(
            region: TCRegion? = nil,
            language: TCServiceConfig.Language? = nil,
            endpoint: TCServiceConfig.EndpointPreference? = nil,
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

    private init(
        service: TCServiceConfig,
        with patch: Patch
    ) {
        if let region = patch.region {
            self.region = region
            self.endpoint = (patch.endpoint ?? service.endpointPreference).resolve(region: region, service: service.service)
        } else {
            self.region = service.region
            self.endpoint = patch.endpoint?.resolve(region: region, service: service.service) ?? service.endpoint
        }
        self.service = service.service
        self.apiVersion = service.apiVersion
        self.language = patch.language ?? service.language
        self.endpointPreference = service.endpointPreference
        self.errorType = service.errorType
        self.timeout = patch.timeout ?? service.timeout
        self.byteBufferAllocator = patch.byteBufferAllocator ?? service.byteBufferAllocator
    }
}
