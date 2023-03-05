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

import TecoCore

extension TCClient {
    /// Errors returned by ``TCClient`` pagination helpers.
    public enum PaginationError: Error, Equatable {
        /// Total item count changed during pagination.
        case totalCountChanged
    }
}

extension TCClient.PaginationError: CustomStringConvertible {
    /// Human readable description of ``TCClient/PaginationError``.
    public var description: String {
        switch self {
        case .totalCountChanged:
            return "Total item count changed during pagination."
        }
    }
}
