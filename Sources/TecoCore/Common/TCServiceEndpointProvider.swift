//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.URL

/// Endpoint provider for the Tencent Cloud service.
public struct TCServiceEndpointProvider: Sendable {
    private static let defaultDomain = "tencentcloudapi.com"

    private let provider: @Sendable (String, TCRegion?) -> String
    private let placeholder: String

    private init(_ description: String, provider: @escaping @Sendable (String, TCRegion?) -> String) {
        self.provider = provider
        self.placeholder = description
    }

    internal func getEndpoint(for service: String, region: TCRegion? = nil) -> String {
        self.provider(service, region)
    }

    /// Prefer to use the endpoint of service region.
    public static var service: TCServiceEndpointProvider {
        TCServiceEndpointProvider("https://<service>.<region>.\(Self.defaultDomain)") { service, region in
            if let region = region {
                return "https://\(service).\(region.rawValue).\(Self.defaultDomain)"
            } else {
                return "https://\(service).\(Self.defaultDomain)"
            }
        }
    }

    /// Prefer to use the global endpoint.
    public static var global: TCServiceEndpointProvider {
        TCServiceEndpointProvider("https://<service>.\(Self.defaultDomain)") { service, region in
            if let region = region, region.kind != .global {
                return "https://\(service).\(region.rawValue).\(Self.defaultDomain)"
            } else {
                return "https://\(service).\(Self.defaultDomain)"
            }
        }
    }

    /// Use the endpoint of provided region.
    public static func regional(_ region: TCRegion) -> TCServiceEndpointProvider {
        TCServiceEndpointProvider("https://<service>.\(region).\(Self.defaultDomain)") { service, _ in
            "https://\(service).\(region.rawValue).\(Self.defaultDomain)"
        }
    }

    /// Provide a static endpoint.
    public static func `static`(_ url: String) -> TCServiceEndpointProvider {
        TCServiceEndpointProvider(url, provider: { _, _ in url })
    }

    /// Provide an endpoint based on service configuration.
    ///
    /// - Parameters:
    ///   - provider: Callback closure which calculates the endpoint URL from service name and region.
    ///   - placeholder: Placeholder description for the provider.
    public static func provider(
        _ provider: @escaping @Sendable (String, TCRegion?) -> String,
        placeholder: String = "<custom endpoint provider>"
    ) -> TCServiceEndpointProvider {
        TCServiceEndpointProvider(placeholder, provider: provider)
    }
}

extension TCServiceEndpointProvider: LosslessStringConvertible {
    /// Create a ``TCServiceEndpointProvider`` from URL string.
    ///
    /// - Parameter url: The endpoint URL string.
    public init?(_ url: String) {
        guard let url = URL(string: url), url.scheme == "http" || url.scheme == "https" else {
            return nil
        }
        self = .static(url.standardized.absoluteString)
    }

    public var description: String {
        self.placeholder
    }
}
