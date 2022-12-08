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

/// Standard Error type returned by Teco.
///
/// Initialized with error code and message.
public protocol TCErrorType: Error, CustomStringConvertible {
    /// Possible error domains related to the base error type.
    static var domains: [TCErrorType.Type] { get }
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

    public static var domains: [TCErrorType.Type] {
        return []
    }
}
