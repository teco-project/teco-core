//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
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
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.TimeInterval
import Logging
import NIOConcurrencyHelpers
import NIOCore
import TecoSigner

/// Wrap a credential provider that returns an ``ExpiringCredential``.
///
/// Used for wrapping another credential provider whose ``CredentialProvider/getCredential(on:logger:)`` method returns an ``ExpiringCredential``.
///
/// If current credential has not expired, it is returned. If no credential is available, or the current credential is going to expire in the near future, the wrapped credential provider's `getCredential` will be called and awaited.
public final class TemporaryCredentialProvider: CredentialProvider {
    private let reservedLifetimeForUse: TimeInterval

    private let provider: CredentialProvider
    private let lock = NIOLock()
    private var credential: Credential?
    private var credentialFuture: EventLoopFuture<Credential>?

    /// Create a ``TemporaryCredentialProvider``.
    ///
    /// - Parameters:
    ///   - context: Provides the `EventLoop` that ``getCredential(on:logger:)`` should run on.
    ///   - provider: Credential provider to wrap.
    ///   - reservedLifetimeForUse: Reserved lifetime for the returned credential.
    public init(context: CredentialProviderFactory.Context, provider: CredentialProvider, reservedLifetimeForUse: TimeInterval = 3 * 60) {
        self.provider = provider
        self.reservedLifetimeForUse = reservedLifetimeForUse
        _ = refreshCredentials(on: context.eventLoop, logger: context.logger)
    }

    public func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        self.lock.withLock {
            if let future = credentialFuture {
                return future.and(provider.shutdown(on: eventLoop)).map { _ in }.hop(to: eventLoop)
            }
            return provider.shutdown(on: eventLoop)
        }
    }

    public func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
        let cred = self.lock.withLock { credential }

        switch cred {
        case .none:
            return self.refreshCredentials(on: eventLoop, logger: logger)
        case .some(let cred as ExpiringCredential):
            if cred.isExpiring(within: reservedLifetimeForUse) {
                // the credentials are expiring... let's refresh
                return self.refreshCredentials(on: eventLoop, logger: logger)
            }
            return eventLoop.makeSucceededFuture(cred)
        case .some(let cred):
            // we don't have expiring credentials
            return eventLoop.makeSucceededFuture(cred)
        }
    }

    private func refreshCredentials(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
        self.lock.lock()
        defer { self.lock.unlock() }

        if let future = credentialFuture {
            // a refresh is already running
            if future.eventLoop !== eventLoop {
                // We want to hop back to the event loop we came in case
                // the refresh is resolved on another EventLoop.
                return future.hop(to: eventLoop)
            }
            return future
        }

        logger.debug("Tencent Cloud credential needs to be refreshed", metadata: ["tc-credential-provider": "\(self)"])

        credentialFuture = self.provider.getCredential(on: eventLoop, logger: logger)
            .map { credential -> (Credential) in
                // update the internal credential with lock
                self.lock.withLock {
                    self.credentialFuture = nil
                    self.credential = credential
                    logger.debug("Tencent Cloud credential was ready", metadata: ["tc-credential-provider": "\(self)"])
                }
                return credential
            }

        return credentialFuture!
    }
}

extension TemporaryCredentialProvider: CustomStringConvertible {
    public var description: String { "\(type(of: self))(\(provider.description))" }
}

#if compiler(>=5.6)
// can use @unchecked Sendable here as access is protected by 'NIOLock'
extension TemporaryCredentialProvider: @unchecked Sendable {}
#endif
