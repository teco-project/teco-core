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

/// Get credentials from a list of possible credential providers.
///
/// Goes through the list of providers in order until a credential is supplied, and uses the successful provider.
class RuntimeSelectorCredentialProvider: CredentialProviderSelector {
    /// Promise to find a credential provider.
    let startupPromise: EventLoopPromise<CredentialProvider>
    /// The provider chosen to supply credentials.
    let internalProvider = NIOLockedValueBox<CredentialProvider?>(nil)

    /// Create a ``RuntimeSelectorCredentialProvider``.
    ///
    /// - Parameters:
    ///   - providers: An ordered list of possible credential providers.
    ///   - context: Provides the `EventLoop` that `getCredential` should run on.
    init(providers: [CredentialProviderFactory], context: CredentialProviderFactory.Context) {
        self.startupPromise = context.eventLoop.makePromise(of: CredentialProvider.self)
        self.startupPromise.futureResult.whenSuccess { result in
            self.internalProvider.withLockedValue { $0 = result }
        }
        self.setupInternalProvider(providers: providers, context: context)
    }

    /// Go through the list of providers.
    ///
    /// If a provider is able to provide credentials then use that one, otherwise move onto the next provider in the list.
    private func setupInternalProvider(providers: [CredentialProviderFactory], context: CredentialProviderFactory.Context) {
        func _setupInternalProvider(_ index: Int) {
            guard index < providers.count else {
                self.startupPromise.fail(CredentialProviderError.noProvider)
                return
            }
            let providerFactory = providers[index]
            let provider = providerFactory.createProvider(context: context)
            provider.getCredential(on: context.eventLoop, logger: context.logger).whenComplete { result in
                switch result {
                case .success:
                    context.logger.debug("Credential provider was selected", metadata: ["tc-credential-provider": "\(provider)"])
                    self.startupPromise.succeed(provider)
                case .failure:
                    context.logger.debug("Credential provider failed during selection", metadata: ["tc-credential-provider": "\(provider)"])
                    _setupInternalProvider(index + 1)
                }
            }
        }

        _setupInternalProvider(0)
    }
}

#if compiler(>=5.6)
// can use @unchecked Sendable here as 'internalProvider' is a safe 'NIOLockedValueBox'
extension RuntimeSelectorCredentialProvider: @unchecked Sendable {}
#endif
