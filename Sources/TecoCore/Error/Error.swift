//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Teco project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// This source file was part of the Soto for AWS open source project
//
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOHTTP1
import struct Foundation.UUID

/// Standard Error type returned by Teco.
///
/// Initialized with error code and message.
public protocol TCErrorType: Error, CustomStringConvertible {
    /// Initialize error.
    init?(errorCode: String, context: TCErrorContext)
    /// Error code return by Tencent Cloud.
    var errorCode: String { get }
    /// Additional context information related to the error.
    var context: TCErrorContext? { get }
}

extension TCErrorType {
    public var localizedDescription: String {
        return description
    }

    public var message: String? {
        return context?.message
    }
}

/// Additional information about error
public struct TCErrorContext: Sendable {
    public let requestId: UUID
    public let message: String
    public let responseCode: HTTPResponseStatus
    public let headers: HTTPHeaders
    public let additionalFields: [String: String]

    internal init(
        requestId: UUID,
        message: String,
        responseCode: HTTPResponseStatus,
        headers: HTTPHeaders = [:],
        additionalFields: [String: String] = [:]
    ) {
        self.requestId = requestId
        self.message = message
        self.responseCode = responseCode
        self.headers = headers
        self.additionalFields = additionalFields
    }
}

/// Response Error type returned by Teco if the error code is unrecognised.
public struct TCResponseError: TCErrorType {
    public let errorCode: String
    public let context: TCErrorContext?

    public init(errorCode: String, context: TCErrorContext) {
        self.errorCode = errorCode
        self.context = context
    }

    public var description: String {
        return "\(self.errorCode): \(self.message ?? "")"
    }
}

/// Raw unprocessed error.
///
/// Used when we cannot extract an error code from the Tencent Cloud response. Returns full body of error response.
public struct TCRawError: Error, CustomStringConvertible {
    public let rawBody: String?
    public let context: TCErrorContext

    init(rawBody: String?, context: TCErrorContext) {
        self.rawBody = rawBody
        self.context = context
    }

    public var description: String {
        return "Unhandled error, code: \(self.context.responseCode)\(self.rawBody.map { ", body: \($0)" } ?? "")"
    }
}
