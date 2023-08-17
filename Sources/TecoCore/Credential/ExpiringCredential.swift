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
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if os(Linux) && compiler(>=5.6)
@preconcurrency import struct Foundation.Date
#else
import struct Foundation.Date
#endif
import struct Foundation.TimeInterval
import TecoSigner

/// Credential that may expire over time.
public protocol ExpiringCredential: Credential {
    /// Whether credential will expire within a certain time.
    func isExpiring(within: TimeInterval) -> Bool
}

extension ExpiringCredential {
    /// Has credential expired.
    public var isExpired: Bool {
        isExpiring(within: 0)
    }
}

/// Basic implementation of a struct conforming to ``ExpiringCredential``.
public struct TemporaryCredential: ExpiringCredential {
    public let secretId: String
    public let secretKey: String
    public let token: String?
    public let expiration: Date

    public init(secretId: String, secretKey: String, token: String?, expiration: Date) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.token = token
        self.expiration = expiration
    }

    public func isExpiring(within interval: TimeInterval) -> Bool {
        self.expiration.timeIntervalSinceNow < interval
    }
}
