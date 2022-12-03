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

/// Protocol for providing credential details for accessing Tencent Cloud services.
public protocol Credential: Codable, Sendable {
    var secretId: String { get }
    var secretKey: String { get }
    /// The federation token of your credential. If this field is specified, `secretId` and `secretKey`
    /// should be set accordingly, see: https://cloud.tencent.com/document/product/598/13896
    var token: String? { get }
}

/// Basic version of ``Credential`` where you supply the credentials.
public struct StaticCredential: Credential, Equatable {
    public let secretId: String
    public let secretKey: String
    public let token: String?

    public init(secretId: String, secretKey: String, token: String? = nil) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.token = token
    }
}
