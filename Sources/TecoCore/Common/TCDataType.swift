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
public protocol TCDataType: Sendable {}

/// TCDataType that can be encoded into API input
public protocol TCEncodableData: TCDataType & Encodable {}

/// TCDataType that can be decoded from API output
public protocol TCDecodableData: TCDataType & Decodable {}
