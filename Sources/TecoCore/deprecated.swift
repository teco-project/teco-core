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

import Foundation
import Logging
import NIOCore
@_implementationOnly import NIOFoundationCompat
import NIOHTTP1

/// ``TCInputModel`` that serves as request payload.
@available(*, deprecated, renamed: "TCRequest")
public typealias TCRequestModel = TCRequest

/// ``TCOutputModel`` that serves as response payload.
///
/// Holds the request ID assigned by Tencent Cloud.
@available(*, deprecated, renamed: "TCResponse")
public typealias TCResponseModel = TCResponse

/// Holds a request or response payload.
///
/// Currently request or response payloads only come in the form of a `ByteBuffer`.
@available(*, deprecated, message: "'TCPayload' is deprecated. Use 'ByteBuffer' directly instead.")
public struct TCPayload: Sendable {
    /// Internal enum for ``TCPayload``.
    enum Payload: Sendable {
        case byteBuffer(ByteBuffer)
        case empty
    }

    internal let payload: Payload

    /// Construct a payload from a `ByteBuffer`.
    public static func byteBuffer(_ buffer: ByteBuffer) -> Self {
        TCPayload(payload: .byteBuffer(buffer))
    }

    /// Construct an empty payload.
    public static var empty: Self {
        TCPayload(payload: .empty)
    }

    /// Construct a payload from raw data (aka. `[UInt8]`).
    public static func data<C: Collection>(_ data: C, byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()) -> Self where C.Element == UInt8 {
        var byteBuffer = byteBufferAllocator.buffer(capacity: data.count)
        byteBuffer.writeBytes(data)
        return TCPayload(payload: .byteBuffer(byteBuffer))
    }

    /// Construct a payload from a `String`.
    public static func string(_ string: String, byteBufferAllocator: ByteBufferAllocator = ByteBufferAllocator()) -> Self {
        var byteBuffer = byteBufferAllocator.buffer(capacity: string.utf8.count)
        byteBuffer.writeString(string)
        return TCPayload(payload: .byteBuffer(byteBuffer))
    }

    /// The size of the payload.
    public var size: Int? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer.readableBytes
        case .empty:
            return 0
        }
    }

    /// Get the payload as `Data`.
    public func asData() -> Data? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes, byteTransferStrategy: .noCopy)
        default:
            return nil
        }
    }

    /// Get the payload as `String`.
    public func asString() -> String? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer.getString(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
        default:
            return nil
        }
    }

    /// Get the payload as `ByteBuffer`.
    public func asByteBuffer() -> ByteBuffer? {
        switch self.payload {
        case .byteBuffer(let byteBuffer):
            return byteBuffer
        default:
            return nil
        }
    }

    /// Whether the payload consists of zero bytes.
    public var isEmpty: Bool {
        switch self.payload {
        case .byteBuffer(let buffer):
            return buffer.readableBytes == 0
        case .empty:
            return true
        }
    }
}

extension TCClient {
    /// Generate signed headers.
    ///
    /// - Parameters:
    ///    - url : URL to sign (RFC 3986).
    ///    - httpMethod: HTTP method to use (`.GET` or `.POST`).
    ///    - headers: Headers that are to be sent with this URL.
    ///    - body: Payload to sign.
    ///    - serviceConfig: Tencent Cloud service configuration used to sign the URL.
    ///    - skipAuthorization: If "Authorization" header should be set to `SKIP`.
    ///    - logger: Logger to output to.
    /// - Returns: A set of signed headers that include the original headers supplied.
    @available(*, deprecated, renamed: "signHeaders(url:method:headers:body:serviceConfig:skipAuthorization:logger:)")
    public func signHeaders(
        url: URL,
        httpMethod: HTTPMethod,
        headers: HTTPHeaders = HTTPHeaders(),
        body: TCPayload,
        serviceConfig: TCServiceConfig,
        skipAuthorization: Bool = false,
        logger: Logger = TCClient.loggingDisabled
    ) -> EventLoopFuture<HTTPHeaders> {
        let buffer: ByteBuffer?
        switch body.payload {
        case .byteBuffer(let byteBuffer):
            buffer = byteBuffer
        case .empty:
            buffer = nil
        }
        return self.signHeaders(
            url: url,
            method: httpMethod,
            headers: headers,
            body: buffer,
            serviceConfig: serviceConfig,
            skipAuthorization: skipAuthorization,
            logger: logger
        )
    }
}

extension TCService {
    /// Generate signed headers.
    ///
    /// - Parameters:
    ///    - url : URL to sign.
    ///    - httpMethod: HTTP method to use.
    ///    - headers: Headers that are to be sent with this URL.
    ///    - body: Payload to sign.
    ///    - logger: Logger to output to.
    /// - Returns: A set of signed headers that include the original headers supplied.
    @available(*, deprecated, renamed: "signHeaders(url:method:headers:body:logger:)")
    public func signHeaders(
        url: URL,
        httpMethod: HTTPMethod = .POST,
        headers: HTTPHeaders = HTTPHeaders(),
        body: TCPayload = .empty,
        logger: Logger = TCClient.loggingDisabled
    ) -> EventLoopFuture<HTTPHeaders> {
        let buffer: ByteBuffer?
        switch body.payload {
        case .byteBuffer(let byteBuffer):
            buffer = byteBuffer
        case .empty:
            buffer = nil
        }
        return self.signHeaders(
            url: url,
            method: httpMethod,
            headers: headers,
            body: buffer,
            logger: logger
        )
    }
}
