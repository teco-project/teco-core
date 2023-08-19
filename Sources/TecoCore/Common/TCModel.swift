//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022-2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Protocol for the input and output data objects for all Tencent Cloud service commands.
public protocol TCModel: Codable, _TecoSendable {}

/// ``TCModel`` that can be used in API input.
///
/// Provides public initializers for callers to construct.
public protocol TCInputModel: TCModel {}

/// ``TCModel`` that can be decoded from API output.
public protocol TCOutputModel: TCModel {}

/// ``TCInputModel`` that serves as request payload.
public protocol TCRequest: TCInputModel {}

/// ``TCOutputModel`` that serves as response payload.
///
/// Holds the request ID assigned by Tencent Cloud.
public protocol TCResponse: TCOutputModel {
    /// Request ID assigned by Tencent Cloud uniquely for every API request.
    var requestId: String { get }
}
