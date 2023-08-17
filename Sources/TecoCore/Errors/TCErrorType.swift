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

/// Standard error type returned by Tencent Cloud API.
///
/// Initialized with error code and message.
public protocol TCErrorType: Error, CustomStringConvertible {
    /// Error domains affliated to the base error type.
    static var domains: [TCErrorType.Type] { get }

    /// Initialize a Tencent Cloud error.
    init?(errorCode: String, context: TCErrorContext)
    /// Error code return by Tencent Cloud.
    var errorCode: String { get }
    /// Additional context information related to the error.
    var context: TCErrorContext? { get }
}

extension TCErrorType {
    /// Error message returned along with the code.
    public var message: String? {
        context?.message
    }
}

extension TCErrorType {
    public var localizedDescription: String {
        description
    }

    public static var domains: [TCErrorType.Type] {
        []
    }
}
