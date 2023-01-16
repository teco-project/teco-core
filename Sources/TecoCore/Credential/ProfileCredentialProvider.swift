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

@_implementationOnly import INIParser
import NIOCore
import NIOConcurrencyHelpers
import TecoSigner

/// Credential provider that reads the identity from Tecent Cloud credential profile.
final class ProfileCredentialProvider: CredentialProviderSelector {
    /// Promise to find a credential provider.
    let startupPromise: EventLoopPromise<CredentialProvider>

    let lock = NIOLock()
    var _internalProvider: CredentialProvider?

    init(profile: String, path: String? = nil, context: CredentialProviderFactory.Context) {
        self.startupPromise = context.eventLoop.makePromise(of: CredentialProvider.self)
        self.startupPromise.futureResult.whenSuccess { result in
            self.internalProvider = result
        }

        if let credentialsFilePath = path ?? Environment["TENCENTCLOUD_CREDENTIALS_FILE"] {
            Self.credentialProvider(from: credentialsFilePath, for: profile, context: context)
                .cascade(to: self.startupPromise)
        } else {
            Self.credentialProvider(from: "~/.tencentcloud/credentials", for: profile, context: context)
                .flatMapError { _ in
                    Self.credentialProvider(from: "/etc/tencentcloud/credentials", for: profile, context: context)
                }
                .cascade(to: self.startupPromise)
        }
    }

    /// Create a credential provider from Tecent Cloud credential profile.
    ///
    /// - Parameters:
    ///   - credentialsFilePath: Path to the credential profile.
    ///   - profile: Named credential profile to load (usually `default`).
    ///   - context: Credential provider factory context.
    /// - Returns: A ``StaticCredential`` containing the parsed credential.
    static func credentialProvider(
        from credentialsFilePath: String,
        for profile: String,
        context: CredentialProviderFactory.Context
    ) -> EventLoopFuture<CredentialProvider> {
        return FileLoader.loadProfile(path: credentialsFilePath, for: profile, on: context.eventLoop)
            .flatMapErrorThrowing { error in
                // Throw `.noProvider` error if credential file cannot be loaded
                throw error is ProfileCredentialProviderError ? error : CredentialProviderError.noProvider
            }
            .map { cred in cred }
    }
}

enum ProfileCredentialProviderError: Error, Equatable {
    case invalidCredentialFile
    case missingProfile(String)
    case missingSecretId
    case missingSecretKey
}

extension FileLoader {
    /// Load and parse Tecent Cloud credential profile from disk.
    ///
    /// - Parameters:
    ///   - path: File path for the credential profile.
    ///   - profile: Named credential profile to load (usually `default`).
    ///   - eventLoop: `EventLoop` to run on.
    /// - Returns: The parsed credential in ``StaticCredential``.
    fileprivate static func loadProfile(path: String, for profile: String, on eventLoop: EventLoop) -> EventLoopFuture<StaticCredential> {
        self.loadFile(path: path, on: eventLoop) { byteBuffer in
            eventLoop.makeCompletedFuture {
                try self.parseCredentials(from: byteBuffer, for: profile)
            }
        }
    }

    /// Parse the profile credential from the `ByteBuffer`.
    ///
    /// - Parameters:
    ///   - byteBuffer: Holds the file contents to parse.
    ///   - profile: Named credential profile to load (usually `default`).
    /// - Returns: The parsed credential in ``StaticCredential``.
    private static func parseCredentials(from byteBuffer: ByteBuffer, for profile: String) throws -> StaticCredential {
        guard let content = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes),
              let parser = try? INIParser(content)
        else {
            throw ProfileCredentialProviderError.invalidCredentialFile
        }

        guard let settings = parser.sections[profile] else {
            throw ProfileCredentialProviderError.missingProfile(profile)
        }
        guard let secretId = settings["secret_id"] else {
            throw ProfileCredentialProviderError.missingSecretId
        }
        guard let secretKey = settings["secret_key"] else {
            throw ProfileCredentialProviderError.missingSecretKey
        }
        return StaticCredential(secretId: secretId, secretKey: secretKey)
    }
}

#if compiler(>=5.6)
// can use @unchecked Sendable here as `_internalProvider`` is accessed via `internalProvider` which
// protects access with a `NIOLock`
extension ProfileCredentialProvider: @unchecked Sendable {}
#endif
