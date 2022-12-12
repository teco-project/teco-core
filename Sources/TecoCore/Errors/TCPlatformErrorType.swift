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

/// Recognized error type returned by Tencent Cloud API.
public protocol TCPlatformErrorType: TCErrorType, Equatable {
    /// Get the error as ``TCCommonError`` if possible.
    ///
    /// - Returns: ``TCCommonError`` that holds the same error code and context.
    func asCommonError() -> TCCommonError?
}

extension TCPlatformErrorType {
    public var description: String {
        "\(errorCode): \(message ?? "")"
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.errorCode == rhs.errorCode
    }

    public func asCommonError() -> TCCommonError? {
        if let context = self.context, let error = TCCommonError(errorCode: self.errorCode, context: context) {
            return error
        }
        return nil
    }
}
