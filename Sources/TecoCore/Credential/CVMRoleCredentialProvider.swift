//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2023 the Teco project authors
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
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AsyncHTTPClient
#if os(Linux) && compiler(>=5.6)
@preconcurrency import class Foundation.JSONDecoder
#else
import class Foundation.JSONDecoder
#endif
import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Foundation.URL

import Logging
import NIOCore
import NIOHTTP1
import TecoSigner

/// Credential provider that provides temporary credentials from CVM instance metadata.
struct CVMRoleCredentialProvider: CredentialProvider {
    static let endpoint = "http://metadata.tencentyun.com/latest/meta-data/cam/security-credentials"

    /// CAM role credential for a CVM instance.
    struct Metadata: ExpiringCredential, Decodable {
        let secretId: String
        let secretKey: String
        let expiredTime: TimeInterval
        let token: String?
        var expiration: Date {
            Date(timeIntervalSince1970: expiredTime)
        }

        func isExpiring(within interval: TimeInterval) -> Bool {
            return self.expiration.timeIntervalSinceNow < interval
        }

        enum CodingKeys: String, CodingKey {
            case secretId = "TmpSecretId"
            case secretKey = "TmpSecretKey"
            case expiredTime = "ExpiredTime"
            case token = "Token"
        }
    }

    private var credentialURL: URL {
        return URL(string: Self.endpoint)!
    }

    private let httpClient: HTTPClient
    private let roleName: String?
    private let decoder = JSONDecoder()

    init(httpClient: HTTPClient, roleName: String? = nil) {
        self.httpClient = httpClient
        self.roleName = roleName
    }

    func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
        let roleNameFuture: EventLoopFuture<String>
        if let roleName = self.roleName {
            roleNameFuture = eventLoop.makeSucceededFuture(roleName)
        } else {
            roleNameFuture = self.request(
                url: self.credentialURL,
                method: .GET,
                on: eventLoop,
                logger: logger
            ).flatMapThrowing { response -> String in
                // the role name is in the body
                guard response.status == .ok else {
                    throw CVMRoleCredentialProviderError.unexpectedResponseStatus(status: response.status)
                }
                guard var body = response.body, let roleName = body.readString(length: body.readableBytes) else {
                    throw CVMRoleCredentialProviderError.couldNotGetInstanceRoleName
                }
                return roleName
            }
        }
        return roleNameFuture
            .flatMap { roleName -> EventLoopFuture<TCHTTPResponse> in
                // request credentials with the role name
                let url = self.credentialURL.appendingPathComponent(roleName)
                return self.request(url: url, on: eventLoop, logger: logger)
            }
            .flatMapThrowing { response in
                // decode the repsonse payload into the metadata object
                guard response.status == .ok else {
                    throw CVMRoleCredentialProviderError.couldNotGetInstanceMetadata
                }
                guard let body = response.body else {
                    throw CVMRoleCredentialProviderError.missingMetadata
                }
                return try self.decoder.decode(Metadata.self, from: body)
            }
            .map { metadata in metadata }
    }

    private func request(
        url: URL,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = .init(),
        timeout: TimeAmount = .seconds(2),
        on eventLoop: EventLoop,
        logger: Logger
    ) -> EventLoopFuture<TCHTTPResponse> {
        let request = TCHTTPRequest(url: url, method: method, headers: headers, body: .empty)
        return httpClient.execute(request: request, timeout: timeout, on: eventLoop, logger: logger)
    }
}

enum CVMRoleCredentialProviderError: Error {
    case unexpectedResponseStatus(status: HTTPResponseStatus)
    case couldNotGetInstanceRoleName
    case couldNotGetInstanceMetadata
    case missingMetadata
}
