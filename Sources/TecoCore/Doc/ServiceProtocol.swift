//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Service protocol
public enum ServiceProtocol: Sendable {
    case json
    case multipart
    case query
}

extension ServiceProtocol {
    public var contentType: String {
        switch self {
        case .json:
            return "application/json; charset=utf-8"
        case .multipart:
            return "multipart/form-data"
        case .query:
            return "application/x-www-form-urlencoded"
        }
    }
}
