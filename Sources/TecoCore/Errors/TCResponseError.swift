//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Response error type returned by Teco if the error code is unrecognized.
public struct TCResponseError: TCErrorType {
    public let errorCode: String
    public let context: TCErrorContext?

    public init(errorCode: String, context: TCErrorContext) {
        self.errorCode = errorCode
        self.context = context
    }

    public var description: String {
        return "\(self.errorCode): \(self.message ?? "")"
    }
}
