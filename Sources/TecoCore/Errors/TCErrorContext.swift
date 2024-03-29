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

/// Additional information about Tencent Cloud error.
public struct TCErrorContext: Sendable {
    /// Request ID assigned by Tencent Cloud, used for error reporting.
    public let requestId: String?
    /// Error message returned along with the code.
    public let message: String
    /// HTTP response status from Tencent Cloud API service.
    public let responseCode: HTTPResponseStatus
    /// HTTP response headers from Tencent Cloud API service.
    public let headers: HTTPHeaders

    internal init(
        requestId: String? = nil,
        message: String,
        responseCode: HTTPResponseStatus,
        headers: HTTPHeaders = [:]
    ) {
        self.requestId = requestId
        self.message = message
        self.responseCode = responseCode
        self.headers = headers
    }
}
