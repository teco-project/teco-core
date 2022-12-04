//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Holds request or response data that is encoded as base64 during transit
public struct TCBase64Data: Sendable, Equatable {
    let base64String: String

    /// Initialize TCBase64Data
    /// - Parameter base64String: base64 encoded data
    private init(base64String: String) {
        self.base64String = base64String
    }

    /// Construct `TCBase64Data` from raw data.
    public static func data<C: Collection>(_ data: C) -> Self where C.Element == UInt8 {
        return .init(base64String: String(base64Encoding: data))
    }

    /// Construct `TCBase64Data` from base64 encoded data.
    public static func base64(_ base64String: String) -> Self {
        return .init(base64String: base64String)
    }

    /// Size of base64 data
    public var base64count: Int {
        return self.base64String.count
    }

    /// return blob as Data
    public func decoded() -> [UInt8]? {
        return try? self.base64String.base64decoded()
    }
}

extension TCBase64Data: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.base64String = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.base64String)
    }
}
