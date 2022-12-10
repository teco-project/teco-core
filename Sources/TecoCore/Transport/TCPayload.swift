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
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2020-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import NIOFoundationCompat
import NIOCore

/// Holds a request or response payload.
///
/// A request payload can be in the form of either a ByteBuffer or a stream
/// function that will supply ByteBuffers to the HTTP client.
/// A response payload only comes in the form of a ByteBuffer
public struct TCPayload: Sendable {
    /// Internal enum
    enum Payload: Sendable {
        case byteBuffer(ByteBuffer)
        case empty
    }

    internal let payload: Payload

    /// construct a payload from a ByteBuffer
    public static func byteBuffer(_ buffer: ByteBuffer) -> Self {
        return TCPayload(payload: .byteBuffer(buffer))
    }

    /// construct an empty payload
    public static var empty: Self {
        return TCPayload(payload: .empty)
    }

    /// Construct a payload from a Collection of UInt8
    public static func data<C: Collection>(_ data: C, byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()) -> Self where C.Element == UInt8 {
        var byteBuffer = byteBufferAllocator.buffer(capacity: data.count)
        byteBuffer.writeBytes(data)
        return TCPayload(payload: .byteBuffer(byteBuffer))
    }

    /// Construct a payload from a `String`
    public static func string(_ string: String, byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()) -> Self {
        var byteBuffer = byteBufferAllocator.buffer(capacity: string.utf8.count)
        byteBuffer.writeString(string)
        return TCPayload(payload: .byteBuffer(byteBuffer))
    }

    /// Return the size of the payload. If the payload is a stream it is always possible to return a size
    public var size: Int? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer.readableBytes
        case .empty:
            return 0
        }
    }

    /// return payload as Data
    public func asData() -> Data? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes, byteTransferStrategy: .noCopy)
        default:
            return nil
        }
    }

    /// return payload as String
    public func asString() -> String? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer.getString(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
        default:
            return nil
        }
    }

    /// return payload as ByteBuffer
    public func asByteBuffer() -> ByteBuffer? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer
        default:
            return nil
        }
    }

    /// does payload consist of zero bytes
    public var isEmpty: Bool {
        switch self.payload {
        case .byteBuffer(let buffer):
            return buffer.readableBytes == 0
        case .empty:
            return true
        }
    }
}

extension TCPayload: Decodable {
    // TCPayload has to conform to Decodable so I can add it to TCModel objects (which conform to Decodable). But we don't want the
    // Encoder/Decoder ever to process a TCPayload
    public init(from decoder: Decoder) throws {
        preconditionFailure("Cannot decode an TCPayload")
    }
}
