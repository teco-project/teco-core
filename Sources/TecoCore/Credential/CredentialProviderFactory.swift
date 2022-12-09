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

/// Provides factory functions for `CredentialProvider`s.
///
/// The factory functions are only called once the `TCClient` has been setup. This means we can supply
/// things like a `Logger`, `EventLoop` and `HTTPClient` to the credential provider when we construct it.
public struct CredentialProviderFactory {
    /// The initialization context for a `ContextProvider`
    public struct Context {
        /// The `TCClient`s internal `HTTPClient`
        public let httpClient: HTTPClient
        /// The `EventLoop` that the `CredentialProvider` should use for credential refreshs
        public let eventLoop: EventLoop
        /// The `Logger` attached to the TCClient
        public let logger: Logger
        /// TCClient options
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
    /// The default CredentialProvider used to access credentials
    public static var `default`: CredentialProviderFactory {
        return .selector(.environment)
    }

    /// Create a custom `CredentialProvider`
    public static func custom(_ factory: @escaping (Context) -> CredentialProvider) -> CredentialProviderFactory {
        Self(cb: factory)
    }

    /// Get `CredentialProvider` details from the environment
    /// Looks in environment variables `TENCENTCLOUD_SECRET_ID`, `TENCENTCLOUD_SECRET_KEY` and `TENCENTCLOUD_TOKEN`.
    public static var environment: CredentialProviderFactory {
        Self { _ -> CredentialProvider in
            return StaticCredential.fromEnvironment() ?? NullCredentialProvider()
        }
    }

    /// Return static credentials.
    public static func `static`(secretId: String, secretKey: String, token: String? = nil) -> CredentialProviderFactory {
        Self { _ in
            StaticCredential(secretId: secretId, secretKey: secretKey, token: token)
        }
    }

    /// Don't supply any credentials
    public static var empty: CredentialProviderFactory {
        Self { _ in
            StaticCredential(secretId: "", secretKey: "")
        }
    }

    /// Use the list of credential providers supplied to get credentials.
    ///
    /// When searching for credentials it will go through the list sequentially and the first credential
    /// provider that returns valid credentials will be used.
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
