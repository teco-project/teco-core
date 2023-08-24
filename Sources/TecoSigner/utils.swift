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

import struct Foundation.URLComponents

extension URLComponents {
    /// Initialize with a URL string, enforcing RFC 3986 validation.
    ///
    /// - Parameter string: The URL string.
    /// - Returns: A `URLComponents` struct for a valid URL, or `nil` if the URL is invalid according to RFC 3986.
    init?(validating string: String) {
#if canImport(Darwin)
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            self.init(string: string, encodingInvalidCharacters: false)
        } else {
            self.init(string: string)
        }
#else
        self.init(string: string)
#endif
    }
}
