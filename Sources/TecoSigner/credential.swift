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

#if compiler(>=5.6)
public typealias _SignerSendable = Sendable
#else
public typealias _SignerSendable = Any
#endif

/// Protocol for providing credential details for accessing Tencent Cloud services.
public protocol Credential: Codable, _SignerSendable {
    /// The credential key ID.
    var secretId: String { get }
    /// The credential key.
    var secretKey: String { get }

    /// The security token of your credential.
    ///
    /// If this field is specified, ``secretId`` and ``secretKey`` should be set accordingly.
    var token: String? { get }
}

/// Basic implementation of a Tencent Cloud ``Credential``.
public struct StaticCredential: Credential, Equatable {
    /// The credential key ID.
    public let secretId: String
    /// The credential key.
    public let secretKey: String
    /// The security token of your credential.
    ///
    /// If this field is specified, ``secretId`` and ``secretKey`` should be set accordingly.
    public let token: String?

    /// Returns a static Tencent Cloud credential.
    public init(secretId: String, secretKey: String, token: String? = nil) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.token = token
    }
}
