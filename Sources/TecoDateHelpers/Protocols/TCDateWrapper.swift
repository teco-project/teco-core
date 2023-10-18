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

public protocol TCDateWrapper: Codable, _TecoDateSendable {
    associatedtype WrappedValue: TCDateValue
    associatedtype Formatter: TCDateFormatter

    var wrappedValue: WrappedValue { get }
    var projectedValue: StorageValue { get nonmutating set }

    init(wrappedValue: WrappedValue)

    @_spi(_TecoInternals) static var _formatter: Formatter { get }
    @_spi(_TecoInternals) static var _valueDescription: StaticString { get }
}

extension TCDateWrapper {
    public typealias StorageValue = WrappedValue.Storage

    public func encode(to encoder: Encoder) throws {
        try self.projectedValue.encode(to: encoder)
    }
}

extension Swift.KeyedEncodingContainer {
    public mutating func encode<Wrapper: TCDateWrapper>(_ value: Wrapper, forKey key: K) throws where Wrapper.WrappedValue.Storage: ExpressibleByNilLiteral {
        try self.encodeIfPresent(value.projectedValue, forKey: key)
    }
}

extension Swift.KeyedDecodingContainer {
    public func decode<Wrapper: TCDateWrapper>(_ type: Wrapper.Type, forKey key: K) throws -> Wrapper where Wrapper.WrappedValue: ExpressibleByNilLiteral {
        if let value = try self.decodeIfPresent(type, forKey: key) {
            return value
        }
        return Wrapper(wrappedValue: nil)
    }
}
