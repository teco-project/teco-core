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

extension TCClient {
    /// A globally shared, singleton ``TCClient``.
    ///
    /// This shared client instance uses a singleton `EventLoopGroup` and cannot be shut down.
    public static var shared: TCClient {
        globallySharedTCClient
    }
}

private let globallySharedTCClient: TCClient = {
    let client = TCClient(
        credentialProvider: .default,
        retryPolicy: .default,
        options: .init(),
        httpClientProvider: .createNew,
        canBeShutdown: false,
        logger: TCClient.loggingDisabled
    )
    return client
}()
