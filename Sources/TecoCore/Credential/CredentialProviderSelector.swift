//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
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
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Logging
import NIOConcurrencyHelpers
import NIOCore
import TecoSigner

/// ``CredentialProvider`` that uses an internal ``CredentialProvider``.
///
/// Once you decide the internal provider, it should be supplied to the ``startupPromise``, and you should set ``internalProvider`` when the ``setupPromise`` result is available.
///
/// ```swift
/// init(providers: [CredentialProviderFactory], context: CredentialProviderFactory.Context) {
///    self.startupPromise = context.eventLoop.makePromise(of: CredentialProvider.self)
///    self.startupPromise.futureResult.whenSuccess { result in
///        self.internalProvider = result
///    }
///    self.setupInternalProvider(providers: providers, context: context)
/// }
/// ```
protocol CredentialProviderSelector: CredentialProvider, AnyObject {
    /// Promise to find a credential provider.
    var startupPromise: EventLoopPromise<CredentialProvider> { get }
    /// Access lock for ``internalProvider``.
    var lock: NIOLock { get }
    /// The storage of ``internalProvider``. **Do not access directly.**
    var _internalProvider: CredentialProvider? { get set }
}

extension CredentialProviderSelector {
    /// The provider chosen to supply credentials.
    var internalProvider: CredentialProvider? {
        get {
            self.lock.withLock {
                _internalProvider
            }
        }
        set {
            self.lock.withLock {
                _internalProvider = newValue
            }
        }
    }

    func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        self.startupPromise.futureResult.flatMap { provider in
            provider.shutdown(on: eventLoop)
        }.hop(to: eventLoop)
    }

    func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential> {
        if let provider = internalProvider {
            return provider.getCredential(on: eventLoop, logger: logger)
        }

        return self.startupPromise.futureResult.hop(to: eventLoop).flatMap { provider in
            provider.getCredential(on: eventLoop, logger: logger)
        }
    }
}
