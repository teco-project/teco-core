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

/// Additional information about Tencent Cloud error.
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
