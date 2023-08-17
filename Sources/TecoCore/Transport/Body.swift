//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// This source file was part of the Soto for AWS open source project
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

import NIOCore

/// Enumaration used to store request/response body in various forms.
enum Body {
    /// JSON data in `ByteBuffer`.
    case json(ByteBuffer)
    /// Empty body.
    case empty
}

extension Body {
    /// Returns as payload.
    func asPayload() -> TCPayload {
        switch self {
        case .json(let buffer):
            if buffer.readableBytes == 0 {
                return .empty
            } else {
                return .byteBuffer(buffer)
            }

        case .empty:
            return .empty
        }
    }

    /// Returns as `ByteBuffer`.
    func asByteBuffer() -> ByteBuffer? {
        return asPayload().asByteBuffer()
    }

    var isEmpty: Bool {
        switch self {
        case .json(let buffer):
            return buffer.readableBytes == 0
        case .empty:
            return true
        }
    }
}
