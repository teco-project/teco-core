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

/// Creates an ``EndpointProvider`` for ``TCService`` to use.
public struct EndpointProviderFactory {
    public let endpointProvider: EndpointProvider

    /// Prefer to use the endpoint of service region.
    public static var service: EndpointProviderFactory {
        .init(endpointProvider: ServiceEndpointFirst())
    }

    /// Prefer to use the global endpoint.
    public static var global: EndpointProviderFactory {
        .init(endpointProvider: GlobalEndpointFirst())
    }

    /// Use the endpoint of provided region.
    public static func regional(_ region: TCRegion) -> EndpointProviderFactory {
        .init(endpointProvider: RegionalEndpoint(region: region))
    }

    /// Provide a static endpoint.
    public static func `static`(_ url: String) -> EndpointProviderFactory {
        .init(endpointProvider: StaticEndpoint(url: url))
    }
}

/// Provider for Tencent Cloud service endpoint.
public protocol EndpointProvider: Sendable, CustomStringConvertible {
    /// Returns the endpoint URL for provided service and region.
    func getEndpoint(for service: String, region: TCRegion?) -> String
}

private struct ServiceEndpointFirst: EndpointProvider {
    var description: String { "https://<service>.<region>.tencentcloudapi.com" }

    func getEndpoint(for service: String, region: TCRegion?) -> String {
        if let region = region {
            return "https://\(service).\(region.rawValue).tencentcloudapi.com"
        } else {
            return "https://\(service).tencentcloudapi.com"
        }
    }
}

private struct GlobalEndpointFirst: EndpointProvider {
    var description: String { "https://<service>.tencentcloudapi.com" }

    func getEndpoint(for service: String, region: TCRegion?) -> String {
        if let region = region, region.kind != .global {
            return "https://\(service).\(region.rawValue).tencentcloudapi.com"
        } else {
            return "https://\(service).tencentcloudapi.com"
        }
    }
}

private struct StaticEndpoint: EndpointProvider {
    let url: String
    var description: String { self.url }

    func getEndpoint(for service: String, region: TCRegion?) -> String {
        return self.url
    }
}

private struct RegionalEndpoint: EndpointProvider {
    let region: TCRegion
    var description: String { "https://<service>.\(self.region.rawValue).tencentcloudapi.com" }

    func getEndpoint(for service: String, region: TCRegion?) -> String {
        "https://<service>.\(self.region.rawValue).tencentcloudapi.com"
    }
}
