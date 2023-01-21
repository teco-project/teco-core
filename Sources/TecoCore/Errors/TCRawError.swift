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

/// Raw unprocessed error.
///
/// Used when we cannot extract an error code from the Tencent Cloud response. Contains full body of error response.
public struct TCRawError: Error, CustomStringConvertible {
    public let rawBody: String?
    public let context: TCErrorContext

    internal init(rawBody: String?, context: TCErrorContext) {
        self.rawBody = rawBody
        self.context = context
    }

    public var description: String {
        return "Unhandled error, code: \(self.context.responseCode)\(self.rawBody.map { ", body: \($0)" } ?? "")"
    }
}
