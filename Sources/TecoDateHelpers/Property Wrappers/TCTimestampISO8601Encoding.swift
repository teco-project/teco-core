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

// THIS FILE IS AUTOMATICALLY GENERATED by TecoDateWrapperGenerator.
// DO NOT EDIT.

import struct Foundation.Date
import class Foundation.ISO8601DateFormatter

@propertyWrapper
public struct TCTimestampISO8601Encoding<WrappedValue: TCDateValue>: Codable {
    public var wrappedValue: WrappedValue {
        self._dateValue
    }

    public var projectedValue: StorageValue {
        get {
            self._stringValue
        }
        set {
            self._stringValue = newValue
        }
    }

    private var _dateValue: WrappedValue

    private var _stringValue: StorageValue

    public init(wrappedValue: WrappedValue) {
        self._dateValue = wrappedValue
        self._stringValue = wrappedValue.encode(formatter: Self._formatter)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self._stringValue = try container.decode(StorageValue.self)
        self._dateValue = try WrappedValue.decode(from: self._stringValue, formatter: Self._formatter, container: container, wrapper: Self.self)
    }
}

extension TCTimestampISO8601Encoding: TCDateWrapper {
    public static var _valueDescription: String {
        "timestamp"
    }

    public static var _formatter: ISO8601DateFormatter {
        ISO8601DateFormatter()
    }
}