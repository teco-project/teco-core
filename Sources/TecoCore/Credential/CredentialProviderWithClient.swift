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

import NIOCore

/// Credential provider that holds a ``TCClient``.
protocol CredentialProviderWithClient: CredentialProvider {
    var client: TCClient { get }
}

extension CredentialProviderWithClient {
    /// Shut down the credential provider and its client.
    func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        client.shutdown { error in
            if let error = error {
                promise.completeWith(.failure(error))
            } else {
                promise.completeWith(.success(()))
            }
        }
        return promise.futureResult
    }
}
