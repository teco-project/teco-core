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

import struct Foundation.Date
import struct Foundation.TimeInterval
import TecoSigner

/// Credential provider whose credentials expire over time.
public protocol ExpiringCredential: Credential {
    /// Will credential expire within a certain time.
    func isExpiring(within: TimeInterval) -> Bool
}

public extension ExpiringCredential {
    /// Has credential expired.
    var isExpired: Bool {
        isExpiring(within: 0)
    }
}

/// Basic implementation of a struct conforming to ``ExpiringCredential``.
public struct RotatingCredential: ExpiringCredential {
    public init(secretId: String, secretKey: String, token: String?, expiration: Date) {
        self.secretId = secretId
        self.secretKey = secretKey
        self.token = token
        self.expiration = expiration
    }

    /// Will credential expire within a certain time
    public func isExpiring(within interval: TimeInterval) -> Bool {
        return self.expiration.timeIntervalSinceNow < interval
    }

    public let secretId: String
    public let secretKey: String
    public let token: String?
    public let expiration: Date
}
