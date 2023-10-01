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

import struct Foundation.Date
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter

public protocol TCDateValue: _TecoDateSendable {
    associatedtype Storage: Codable, _TecoDateSendable

    func encode(formatter: TCDateFormatter) -> Storage
    static func decode<Wrapper: TCDateWrapper>(from storageValue: Storage, formatter: TCDateFormatter, container: SingleValueDecodingContainer, wrapper: Wrapper.Type) throws -> Self
}

extension Foundation.Date: TCDateValue {
    public func encode(formatter: TCDateFormatter) -> String {
        formatter.string(from: self)
    }

    public static func decode<Wrapper: TCDateWrapper>(from stringValue: String, formatter: TCDateFormatter, container: SingleValueDecodingContainer, wrapper: Wrapper.Type = Wrapper.self) throws -> Date {
        guard let date = formatter.date(from: stringValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(wrapper._valueDescription): \(stringValue)")
        }
        return date
    }
}

extension Swift.Optional: TCDateValue where Wrapped == Foundation.Date {
    public func encode(formatter: TCDateFormatter) -> String? {
        switch self {
        case .some(let date):
            return formatter.string(from: date)
        case .none:
            return nil
        }
    }

    public static func decode<Wrapper: TCDateWrapper>(from stringValue: String?, formatter: TCDateFormatter, container: SingleValueDecodingContainer, wrapper: Wrapper.Type = Wrapper.self) throws -> Date? {
        guard let stringValue = stringValue else {
            return nil
        }
        guard let date = formatter.date(from: stringValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid \(wrapper._valueDescription): \(stringValue)")
        }
        return date
    }
}

#if os(Linux) && compiler(>=5.6)
// work around the issue where retroactive Sendable conformance cannot be synthesized by '@preconcurrency'
extension Foundation.Date: @unchecked Sendable {}
#endif
