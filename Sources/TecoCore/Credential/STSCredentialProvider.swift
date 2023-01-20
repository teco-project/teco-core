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
import struct Foundation.Date
import struct Foundation.TimeInterval

struct STSAssumeRoleRequest: TCRequestModel {
    /// Resource descriptions of a role, which can be obtained by clicking the role name in the CAM console.
    ///
    /// General role example:
    /// - `qcs::cam::uin/12345678:role/4611686018427397919`
    /// - `qcs::cam::uin/12345678:roleName/testRoleName`
    ///
    /// Service role example:
    /// - `qcs::cam::uin/12345678:role/tencentcloudServiceRole/4611686018427397920`
    /// - `qcs::cam::uin/12345678:role/tencentcloudServiceRoleName/testServiceRoleName`
    let roleArn: String

    /// User-defined temporary session name.
    ///
    /// It can contain 2-128 letters, digits, and symbols (=,.@-).
    /// Regex: `[\w+=,.@-]*`
    let roleSessionName: String

    /// Specifies the validity period of credentials in seconds.
    ///
    /// Default value: 7200. Maximum value: 43200.
    let durationSeconds: UInt64?

    /// Policy description.
    ///
    /// 1. The policy needs to be URL-encoded.
    /// 2. For the policy syntax, please see CAM's [Syntax Logic](https://www.tencentcloud.com/document/product/598/10603).
    /// 3. The policy cannot contain the `principal` element.
    let policy: String?

    init(roleArn: String, roleSessionName: String, durationSeconds: UInt64? = nil, policy: String? = nil) {
        self.roleArn = roleArn
        self.roleSessionName = roleSessionName
        self.durationSeconds = durationSeconds
        self.policy = policy?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    enum CodingKeys: String, CodingKey {
        case roleArn = "RoleArn"
        case roleSessionName = "RoleSessionName"
        case durationSeconds = "DurationSeconds"
        case policy = "Policy"
    }
}

private struct STSAssumeRoleResponse: TCResponseModel {
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

/// Credential provider that returns temporary credentials acquired from STS.
struct STSCredentialProvider: CredentialProviderWithClient {
    let client: TCClient

    private let config: TCServiceConfig
    private let request: STSAssumeRoleRequest

    init(
        request: STSAssumeRoleRequest,
        credentialProvider: CredentialProviderFactory,
        region: TCRegion? = nil,
        httpClient: HTTPClient,
        endpoint: EndpointProvider = .global
    ) {
        self.client = TCClient(credentialProvider: credentialProvider,
                               httpClientProvider: .shared(httpClient))
        self.config = TCServiceConfig(service: "sts", version: "2018-08-13", region: region, endpoint: endpoint)
        self.request = request
    }

    func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
        self.assumeRole(self.request, logger: logger, on: eventLoop)
            .flatMapThrowing { response in
                let credential = response.credentials
                return TemporaryCredential(
                    secretId: credential.tmpSecretId,
                    secretKey: credential.tmpSecretKey,
                    token: credential.token,
                    expiration: Date(timeIntervalSince1970: .init(response.expiredTime)))
            }
    }

    private func assumeRole(_ input: STSAssumeRoleRequest, logger: Logger = TCClient.loggingDisabled, on eventLoop: EventLoop? = nil) -> EventLoopFuture<STSAssumeRoleResponse> {
        self.client.execute(action: "AssumeRole", serviceConfig: self.config, input: input, logger: logger, on: eventLoop)
    }
}
