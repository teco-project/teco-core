//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
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

#if canImport(Glibc)
@_implementationOnly import Glibc
#elseif canImport(Darwin)
@_implementationOnly import Darwin.C
#elseif canImport(CRT)
@_implementationOnly import CRT
#elseif canImport(WASILibc)
@_implementationOnly import WASILibc
#elseif canImport(Musl)
@_implementationOnly import Musl
#else
#error("Unsupported libc.")
#endif

enum Environment {
    static subscript(_ name: String) -> String? {
        guard let value = getenv(name) else {
            return nil
        }
        return String(cString: value)
    }
}
