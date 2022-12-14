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

public protocol TCDateWrapper: Codable {
    associatedtype WrappedValue: TCDateValue
    associatedtype _Formatter: TCDateFormatter

    var wrappedValue: WrappedValue { get }
    var storageValue: StorageValue { get }
    
    init(wrappedValue: WrappedValue)

    static var _formatter: _Formatter { get }
    static var _valueDescription: String { get }
}

extension TCDateWrapper {
    public typealias StorageValue = WrappedValue.Storage

    public func encode(to encoder: Encoder) throws {
        try self.storageValue.encode(to: encoder)
    }
}

extension Swift.KeyedEncodingContainer {
    public mutating func encode<Wrapper: TCDateWrapper>(_ value: Wrapper, forKey key: K) throws where Wrapper.StorageValue: ExpressibleByNilLiteral {
        try self.encodeIfPresent(value.storageValue, forKey: key)
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
