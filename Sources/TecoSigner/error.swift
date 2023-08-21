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

/// Errors returned by ``TCSignerV3``.
public enum TCSignerError: Error, CustomStringConvertible {
    /// URL provided to the signer is invalid.
    case invalidURL

    /// Human readable description of ``TCSignerError``.
    public var description: String {
        switch self {
        case .invalidURL:
            return "URL provided to the signer is invalid."
        }
    }
}
