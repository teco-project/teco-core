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
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOCore
import AsyncHTTPClient
import TecoSigner

/// Provide factory functionality for ``CredentialProvider``s.
///
/// The factory functions are only called once the ``TCClient`` has been setup.
/// This means we can supply things like a `Logger`, `EventLoop` and `HTTPClient` to the credential provider when we construct it.
public struct CredentialProviderFactory {
    /// The initialization context for a ``CredentialProvider``.
    public struct Context {
        /// The `TCClient`'s internal `HTTPClient`
        public let httpClient: HTTPClient
        /// `EventLoop` that the ``CredentialProvider`` should use for credential refreshs.
        public let eventLoop: EventLoop
        /// `Logger` attached to the `TCClient`.
        public let logger: Logger
        /// `TCClient` options.
        public let options: TCClient.Options
    }

    private let cb: (Context) -> CredentialProvider

    private init(cb: @escaping (Context) -> CredentialProvider) {
        self.cb = cb
    }

    internal func createProvider(context: Context) -> CredentialProvider {
        self.cb(context)
    }
}

extension CredentialProviderFactory {
    /// The default ``CredentialProvider`` used to access credentials.
    public static var `default`: CredentialProviderFactory {
        #if os(Linux)
        return .selector(.environment, .cvm, .tke)
        #else
        return .selector(.environment)
        #endif
    }

    /// Create a custom ``CredentialProvider``.
    public static func custom(_ factory: @escaping (Context) -> CredentialProvider) -> CredentialProviderFactory {
        Self(cb: factory)
    }

    /// Get ``Credential`` details from the environment.
    ///
    /// Looks in environment variables `TENCENTCLOUD_SECRET_ID`, `TENCENTCLOUD_SECRET_KEY` and `TENCENTCLOUD_TOKEN`.
    public static var environment: CredentialProviderFactory {
        Self { _ -> CredentialProvider in
            return StaticCredential.fromEnvironment() ?? NullCredentialProvider()
        }
    }

    /// Provide a static credential.
    public static func `static`(secretId: String, secretKey: String, token: String? = nil) -> CredentialProviderFactory {
        Self { _ in
            StaticCredential(secretId: secretId, secretKey: secretKey, token: token)
        }
    }

    /// Use credentials supplied via the CVM instance role.
    public static var cvm: CredentialProviderFactory {
        Self { context in
            let provider = CVMRoleCredentialProvider(httpClient: context.httpClient)
            return TemporaryCredentialProvider(context: context, provider: provider)
        }
    }

    /// Retrieve identity from the TKE OIDC provider, and acquire temporary credentials with STS.
    public static var tke: CredentialProviderFactory {
        Self { context in
            let provider = OIDCRoleArnCredentialProvider(
                requestProvider: OIDCRoleArnCredentialProvider.makeRequestForTKE,
                httpClient: context.httpClient
            )
            return TemporaryCredentialProvider(context: context, provider: provider)
        }
    }

    /// Use Security Token Service (STS) to acquire temporary credentials.
    ///
    /// - Parameters:
    ///   - roleArn: Resource descriptions of a role, which can be obtained by clicking the role name in the CAM console. Default to look in environment variable `TENCENTCLOUD_ROLE_ARN`.
    ///   - roleSessionName: Temporary session name. Default to look in environment variable `TENCENTCLOUD_ROLE_SESSION_NAME`.
    ///   - policy: Policy description using CAM's [Syntax Logic](https://www.tencentcloud.com/document/product/598/10603). The policy cannot contain the `principal` element.
    ///   - credentialProvider: Credential provider that gives the initial credential.
    public static func sts(
        roleArn: String? = nil,
        roleSessionName: String? = nil,
        policy: String? = nil,
        credentialProvider: CredentialProviderFactory = .`default`
    ) -> CredentialProviderFactory {
        Self { context in
            guard let roleArn = roleArn ?? Environment["TENCENTCLOUD_ROLE_ARN"],
                  let roleSessionName = roleSessionName ?? Environment["TENCENTCLOUD_ROLE_SESSION_NAME"] else {
                return NullCredentialProvider()
            }
            let request = STSAssumeRoleRequest(roleArn: roleArn, roleSessionName: roleSessionName, policy: policy)
            let provider = STSCredentialProvider(request: request, credentialProvider: credentialProvider, httpClient: context.httpClient)
            return TemporaryCredentialProvider(context: context, provider: provider)
        }
    }

    /// Don't supply any credentials.
    public static var empty: CredentialProviderFactory {
        Self { _ in
            StaticCredential(secretId: "", secretKey: "")
        }
    }

    /// Use the list of credential providers supplied to get credentials.
    ///
    /// When searching for credentials it will go through the list sequentially and the first credential provider that returns a valid credential will be used.
    public static func selector(_ providers: CredentialProviderFactory...) -> CredentialProviderFactory {
        Self { context in
            if providers.count == 1 {
                return providers[0].createProvider(context: context)
            } else {
                return RuntimeSelectorCredentialProvider(providers: providers, context: context)
            }
        }
    }
}
