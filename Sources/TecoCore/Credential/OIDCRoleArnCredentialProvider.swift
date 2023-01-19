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

import AsyncHTTPClient
import NIOCore
import struct Foundation.Date
import struct Foundation.TimeInterval

struct STSAssumeRoleWithWebIdentityRequest: TCRequestModel {
    /// Identity provider name.
    let providerId: String
    /// OIDC token issued by the IdP.
    let webIdentityToken: String
    /// Role access description name.
    let roleArn: String
    /// Session name.
    let roleSessionName: String
    /// The validity period of the temporary credential in seconds.
    ///
    /// Default value: 7200. Maximum value: 43200.
    let durationSeconds: Int64?

    init(providerId: String, webIdentityToken: String, roleArn: String, roleSessionName: String, durationSeconds: Int64? = nil) {
        self.providerId = providerId
        self.webIdentityToken = webIdentityToken
        self.roleArn = roleArn
        self.roleSessionName = roleSessionName
        self.durationSeconds = durationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case providerId = "ProviderId"
        case webIdentityToken = "WebIdentityToken"
        case roleArn = "RoleArn"
        case roleSessionName = "RoleSessionName"
        case durationSeconds = "DurationSeconds"
    }
}

private struct STSAssumeRoleWithWebIdentityResponse: TCResponseModel {
    /// Temporary security credentials.
    let credentials: Credentials
    /// Credentials expiration time in Unix timestamp.
    let expiredTime: Int64
    /// The unique request ID, which is returned for each request.
    let requestId: String

    enum CodingKeys: String, CodingKey {
        case credentials = "Credentials"
        case expiredTime = "ExpiredTime"
        case requestId = "RequestId"
    }

    struct Credentials: TCOutputModel {
        let token: String
        let tmpSecretId: String
        let tmpSecretKey: String

        enum CodingKeys: String, CodingKey {
            case token = "Token"
            case tmpSecretId = "TmpSecretId"
            case tmpSecretKey = "TmpSecretKey"
        }
    }
}

/// Credential provider that returns temporary credentials acquired with OIDC.
struct OIDCRoleArnCredentialProvider: CredentialProviderWithClient {
    let client: TCClient
    let config: TCServiceConfig
    let requestProvider: (EventLoop) -> EventLoopFuture<STSAssumeRoleWithWebIdentityRequest>

    init(
        requestProvider: @escaping (EventLoop) -> EventLoopFuture<STSAssumeRoleWithWebIdentityRequest>,
        region: TCRegion? = nil,
        httpClient: HTTPClient,
        endpoint: TCServiceConfig.Endpoint = .global
    ) {
        let region: TCRegion? = {
            if let regionId = Environment["TKE_REGION"] {
                return region ?? TCRegion(id: regionId)
            }
            return region
        }()

        self.client = TCClient(credentialProvider: .empty, httpClientProvider: .shared(httpClient))
        self.config = TCServiceConfig(service: "sts", version: "2018-08-13", region: region, endpoint: endpoint)
        self.requestProvider = requestProvider
    }

    static func makeRequestForTKE(on eventLoop: EventLoop) -> EventLoopFuture<STSAssumeRoleWithWebIdentityRequest> {
        guard let providerId = Environment["TKE_PROVIDER_ID"] else {
            return eventLoop.makeFailedFuture(OIDCRoleArnCredentialProviderError.missingProviderId)
        }
        guard let tokenFile = Environment["TKE_IDENTITY_TOKEN_FILE"] else {
            return eventLoop.makeFailedFuture(OIDCRoleArnCredentialProviderError.missingIdentityTokenFile)
        }
        guard let roleArn = Environment["TKE_ROLE_ARN"] else {
            return eventLoop.makeFailedFuture(OIDCRoleArnCredentialProviderError.missingRoleArn)
        }
        return FileLoader.loadFile(path: tokenFile, on: eventLoop) { byteBuffer in
            guard let identityToken = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) else {
                return eventLoop.makeFailedFuture(OIDCRoleArnCredentialProviderError.couldNotReadIdentityTokenFile)
            }
            let timestamp = UInt64(Date().timeIntervalSince1970 * 1_000_000)
            let request = STSAssumeRoleWithWebIdentityRequest(providerId: providerId, webIdentityToken: identityToken, roleArn: roleArn, roleSessionName: "teco-\(timestamp)")
            return eventLoop.makeSucceededFuture(request)
        }
    }

    func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
        self.requestProvider(eventLoop)
            .flatMap { request in
                self.assumeRoleWithWebIdentity(request, logger: logger, on: eventLoop)
            }
            .flatMapThrowing { response in
                let credential = response.credentials
                return TemporaryCredential(
                    secretId: credential.tmpSecretId,
                    secretKey: credential.tmpSecretKey,
                    token: credential.token,
                    expiration: Date(timeIntervalSince1970: .init(response.expiredTime)))
            }
    }

    private func assumeRoleWithWebIdentity(_ input: STSAssumeRoleWithWebIdentityRequest, logger: Logger = TCClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<STSAssumeRoleWithWebIdentityResponse> {
        self.client.execute(action: "AssumeRoleWithWebIdentity", serviceConfig: self.config, skipAuthorization: true, input: input, logger: logger, on: eventLoop)
    }
}

enum OIDCRoleArnCredentialProviderError: Error {
    case couldNotReadIdentityTokenFile
    case missingProviderId
    case missingIdentityTokenFile
    case missingRoleArn
}
