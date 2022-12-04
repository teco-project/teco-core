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

import func Foundation.NSMakeRange
import var Foundation.NSNotFound
import class Foundation.NSRegularExpression
import struct Foundation.UUID

/// Protocol for the input and output objects for all Tencent Cloud service commands.
///
/// They need to be Codable so they can be serialized.
public protocol TCDataType: Sendable {
    /// The array of members serialization helpers
    static var _encoding: [TCMemberEncoding] { get }
}

extension TCDataType {
    public static var _encoding: [TCMemberEncoding] {
        return []
    }

    /// return member with provided name
    public static func getEncoding(for: String) -> TCMemberEncoding? {
        return _encoding.first { $0.label == `for` }
    }

    /// return list of member variables serialized in the headers
    static var headerParams: [String: String] {
        var params: [String: String] = [:]
        for member in _encoding {
            guard let location = member.location else { continue }
            if case .header(let name) = location {
                params[name] = member.label
            }
        }
        return params
    }

    /// return list of member variables serialized in the headers with a prefix
    static var headerPrefixParams: [String: String] {
        var params: [String: String] = [:]
        for member in _encoding {
            guard let location = member.location else { continue }
            if case .headerPrefix(let name) = location {
                params[name] = member.label
            }
        }
        return params
    }

    /// return list of member variables serialized in the headers
    static var statusCodeParam: String? {
        for member in _encoding {
            guard let location = member.location else { continue }
            if case .statusCode = location {
                return member.label
            }
        }
        return nil
    }
}

extension TCDataType {
    /// Return an idempotencyToken
    public static func idempotencyToken() -> String {
        return UUID().uuidString
    }
}

/// TCDataType that can be encoded into API input
public protocol TCEncodableData: TCDataType & Encodable {}

/// TCDataType that can be decoded from API output
public protocol TCDecodableData: TCDataType & Decodable {}

/// Root TCDataType which include a payload
public protocol TCDataWithPayload: TCDataType {
    /// The path to the object that is included in the request body
    static var _payloadPath: String { get }
}
