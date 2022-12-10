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

/// Protocol for the input and output data objects for all Tencent Cloud service commands.
public protocol TCModel: Sendable {}

/// TCModel that can be encoded into API input
public protocol TCEncodableModel: TCModel & Encodable {}

/// TCModel that can be decoded from API output
public protocol TCDecodableModel: TCModel & Decodable {}

/// TCEncodableModel that serves as request payload
public protocol TCRequestModel: TCEncodableModel {}

/// TCDecodableModel that serves as response payload
public protocol TCResponseModel: TCDecodableModel {
    var requestId: String { get }
}
