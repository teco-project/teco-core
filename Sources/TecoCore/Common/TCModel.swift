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
///
/// The model must be codable in both directions.
public protocol TCModel: Sendable, Codable {}

/// TCModel that can be used in API input.
///
/// Provides public initializers for callers to construct.
public protocol TCInputModel: TCModel {}

/// TCModel that can be decoded from API output
public protocol TCOutputModel: TCModel {}

/// TCInputModel that serves as request payload
public protocol TCRequestModel: TCInputModel {}

/// TCOutputModel that serves as response payload
public protocol TCResponseModel: TCOutputModel {
    var requestId: String { get }
}
