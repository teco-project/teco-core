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
import NIOCore
import TecoSigner

/// Provides Tencent Cloud credentials.
public protocol CredentialProvider: Sendable, CustomStringConvertible {
    /// Return credential.
    /// - Parameters:
    ///   - eventLoop: EventLoop to run on.
    ///   - logger: Logger to use.
    func getCredential(on eventLoop: EventLoop, logger: Logger) -> EventLoopFuture<Credential>

    /// Shutdown credential provider.
    /// - Parameter eventLoop: EventLoop to use when shutiting down.
    func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void>
}

extension CredentialProvider {
    public func shutdown(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        return eventLoop.makeSucceededFuture(())
    }

    public var description: String { return "\(type(of: self))" }
}
