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
    /// Text.
    case text(String)
    /// JSON data in `ByteBuffer`.
    case json(ByteBuffer)
    /// Empty body.
    case empty
}

extension Body {
    /// Returns as a string.
    func asString() -> String? {
        switch self {
        case .text(let text):
            return text
        case .json(let buffer):
            return buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes, encoding: .utf8)
        case .empty:
            return nil
        }
    }

    /// Returns as payload.
    func asPayload(byteBufferAllocator: ByteBufferAllocator) -> TCPayload {
        switch self {
        case .text(let text):
            var buffer = byteBufferAllocator.buffer(capacity: text.utf8.count)
            buffer.writeString(text)
            return .byteBuffer(buffer)

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
    func asByteBuffer(byteBufferAllocator: ByteBufferAllocator) -> ByteBuffer? {
        return asPayload(byteBufferAllocator: byteBufferAllocator).asByteBuffer()
    }

    var isEmpty: Bool {
        switch self {
        case .text(let text):
            return text.count == 0
        case .json(let buffer):
            return buffer.readableBytes == 0
        case .empty:
            return true
        }
    }
}
