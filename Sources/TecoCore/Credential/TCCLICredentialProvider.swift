//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
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

private struct TCCLICredential: Decodable {
    let secretId: String
    let secretKey: String
    let roleArn: String?
    let roleSessionName: String?

    enum CodingKeys: String, CodingKey {
        case secretId
        case secretKey
        case roleArn = "role-arn"
        case roleSessionName = "role-session-name"
    }
}

/// Credential provider that reads the identity from TCCLI credential file.
final class TCCLICredentialProvider: CredentialProviderSelector {
    /// Promise to find a credential provider.
    let startupPromise: EventLoopPromise<CredentialProvider>

    let lock = NIOLock()
    var _internalProvider: CredentialProvider?

    init(profile: String, context: CredentialProviderFactory.Context, region: TCRegion? = nil) {
        self.startupPromise = context.eventLoop.makePromise(of: CredentialProvider.self)
        self.startupPromise.futureResult.whenSuccess { result in
            self.internalProvider = result
        }

        Self.credentialProvider(from: "~/.tccli/\(profile).credential", context: context, region: region)
            .cascade(to: self.startupPromise)
    }

    /// Create a credential provider from TCCLI credential file.
    ///
    /// - Parameters:
    ///   - credentialFilePath: Path to the credential file (usually `~/.tccli/{profile}.credential`).
    ///   - context: Credential provider factory context.
    ///   - region: Preferred region for Security Token Service (STS).
    /// - Returns: A credential provider (either ``StaticCredential`` or ``STSCrendentialProvider``).
    static func credentialProvider(
        from credentialFilePath: String,
        context: CredentialProviderFactory.Context,
        region: TCRegion? = nil
    ) -> EventLoopFuture<CredentialProvider> {
        return FileLoader.loadTCCLICredential(path: credentialFilePath, on: context.eventLoop)
            .flatMapErrorThrowing { _ in
                // Throw `.noProvider` error if credential file cannot be loaded
                throw CredentialProviderError.noProvider
            }
            .flatMapThrowing { credential in
                try credentialProvider(from: credential, context: context, region: region)
            }
    }

    /// Generate credential provider based on TCCLI credential file.
    ///
    /// To learn more about TCCLI profile, see [Configuring TCCLI](https://www.tencentcloud.com/document/product/1013/33465).
    ///
    /// - Parameters:
    ///   - credential: Parsed contents of TCCLI credential file.
    ///   - context: Credential provider factory context.
    ///   - region: Preferred region for Security Token Service (STS).
    /// - Returns: A credential provider (either ``StaticCredential`` or ``STSCrendentialProvider``).
    private static func credentialProvider(
        from credential: TCCLICredential,
        context: CredentialProviderFactory.Context,
        region: TCRegion? = nil
    ) throws -> CredentialProvider {
        guard let roleArn = credential.roleArn,
              let roleSessionName = credential.roleSessionName else {
            return StaticCredential(secretId: credential.secretId, secretKey: credential.secretKey)
        }

        let request = STSAssumeRoleRequest(roleArn:
        roleArn, roleSessionName: roleSessionName)
        return STSCredentialProvider(
            request: request,
            credentialProvider: .static(secretId: credential.secretId, secretKey: credential.secretKey),
            region: region,
            httpClient: context.httpClient
        )
    }
}

extension FileLoader {
    /// Load TCCLI credential from disk.
    ///
    /// - Parameters:
    ///   - path: File path for TCCLI credential file.
    ///   - eventLoop: `EventLoop` to run on.
    fileprivate static func loadTCCLICredential(path: String, on eventLoop: EventLoop) -> EventLoopFuture<TCCLICredential> {
        self.loadFile(path: path, on: eventLoop) { byteBuffer in
            eventLoop.makeCompletedFuture {
                try self.decoder.decode(TCCLICredential.self, from: byteBuffer)
            }
        }
    }
}

#if compiler(>=5.6)
// can use @unchecked Sendable here as `_internalProvider`` is accessed via `internalProvider` which
// protects access with a `NIOLock`
extension TCCLICredentialProvider: @unchecked Sendable {}
#endif
