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

import struct Foundation.UUID

/// Protocol for the input and output data objects for all Tencent Cloud service commands.
public protocol TCDataType: Sendable {}

/// TCDataType that can be encoded into API input
public protocol TCEncodableData: TCDataType & Encodable {}

/// TCEncodableData that serves as request payload
public protocol TCRequestData: TCEncodableData {}

/// TCDataType that can be decoded from API output
public protocol TCDecodableData: TCDataType & Decodable {}

/// TCDecodableData that serves as response payload
public protocol TCResponseData: TCDecodableData {
    var requestId: String { get }
}

extension TCResponseData {
    public var uuid: UUID? { UUID(uuidString: self.requestId) }
}
