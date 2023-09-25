//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.Date
import struct Foundation.URLQueryItem

extension Swift.Sequence where Element == UInt8 {
    /// return a hex-encoded string buffer from an array of bytes
    func hexDigest() -> String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}

extension Swift.Sequence where Element == URLQueryItem {
    func rfc3986Encoded() -> [URLQueryItem] {
        self.map { .init(name: $0.name.rfc3986Encoded(), value: $0.value?.rfc3986Encoded()) }
    }
    func wwwFormURLEncodedString() -> String {
        self.map { "\($0.name.wwwFormURLEncoded())=\($0.value?.wwwFormURLEncoded() ?? "")" }
            .joined(separator: "&")
    }
    func canonicalString() -> String {
        self.map({ "\($0.name)=\($0.value ?? "")" }).joined(separator: "&")
    }
}

extension Foundation.Date {
    /// return a timestamp formatted for signing requests
    var timestamp: String {
        String(UInt64(self.timeIntervalSince1970))
    }
}

extension Swift.RangeReplaceableCollection where Self : MutableCollection, Element == URLQueryItem {
    mutating func replaceOrAdd(name: String, value: String?) {
        let queryItem = URLQueryItem(name: name, value: value)
        if let index = self.firstIndex(where: { $0.name == name }) {
            self[index] = queryItem
        } else {
            self.append(queryItem)
        }
    }
    mutating func remove(name: String) {
        self.removeAll(where: { $0.name == name })
    }
}

private extension Swift.String {
    func rfc3986Encoded() -> String {
        self.addingPercentEncoding(withAllowedCharacters: .init(charactersIn: "-._~").union(.alphanumerics)) ?? self
    }
    func wwwFormURLEncoded() -> String {
        let percentEncoded = self.addingPercentEncoding(withAllowedCharacters: .init(charactersIn: " -._").union(.alphanumerics)) ?? self
        return percentEncoded.replacingOccurrences(of: " ", with: "+")
    }
}
