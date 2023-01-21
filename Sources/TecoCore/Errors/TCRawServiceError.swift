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

/// Service error type returned by Tencent Cloud, with unhandled raw error code.
public struct TCRawServiceError: TCServiceErrorType {
    public let errorCode: String
    public let context: TCErrorContext?

    public init(errorCode: String, context: TCErrorContext) {
        self.errorCode = errorCode
        self.context = context
    }

    internal init(_ errorCode: String, context: TCErrorContext?) {
        self.errorCode = errorCode
        self.context = context
    }

    public func asRawError() -> TCRawServiceError {
        return self
    }
}
