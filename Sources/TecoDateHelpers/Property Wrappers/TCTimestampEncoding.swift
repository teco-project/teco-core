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

// THIS FILE IS AUTOMATICALLY GENERATED by TecoDateWrapperGenerator.
// DO NOT EDIT.

import struct Foundation.Date
import struct Foundation.Locale
import struct Foundation.TimeZone
import class Foundation.DateFormatter
@_implementationOnly import struct NIOConcurrencyHelpers.NIOLockedValueBox

@propertyWrapper
public struct TCTimestampEncoding<WrappedValue: TCDateValue>: Codable {
    public var wrappedValue: WrappedValue {
        self._dateValue
    }

    public var projectedValue: StorageValue {
        get {
            self._stringValue.withLockedValue {
                $0
            }
        }
        nonmutating set {
            self._stringValue.withLockedValue {
                $0 = newValue
            }
        }
    }

    private let _dateValue: WrappedValue

    private let _stringValue: NIOLockedValueBox<StorageValue>

    public init(wrappedValue: WrappedValue) {
        self._dateValue = wrappedValue
        self._stringValue = NIOLockedValueBox(wrappedValue.encode(formatter: Self._formatter))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(StorageValue.self)
        self._dateValue = try WrappedValue.decode(from: dateString, formatter: Self._formatter, container: container, wrapper: Self.self)
        self._stringValue = NIOLockedValueBox(dateString)
    }
}

extension TCTimestampEncoding: TCDateWrapper {
    @_spi(_TecoInternals) public static var _valueDescription: StaticString {
        "timestamp"
    }

    @_spi(_TecoInternals) public static var _formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
        return formatter
    }
}
