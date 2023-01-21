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
//
// This source file was part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import TecoSigner

public extension StaticCredential {
    /// Construct static credential from environment variables if they exist.
    static func fromEnvironment() -> StaticCredential? {
        guard let secretId = Environment["TENCENTCLOUD_SECRET_ID"] else {
            return nil
        }
        guard let secretKey = Environment["TENCENTCLOUD_SECRET_KEY"] else {
            return nil
        }

        return .init(
            secretId: secretId,
            secretKey: secretKey,
            token: Environment["TENCENTCLOUD_TOKEN"]
        )
    }

    /// Construct static credential from SCF environment variables if they exist.
    static func fromSCFEnvironment() -> StaticCredential? {
        guard let secretId = Environment["TENCENTCLOUD_SECRETID"] else {
            return nil
        }
        guard let secretKey = Environment["TENCENTCLOUD_SECRETKEY"] else {
            return nil
        }

        return .init(
            secretId: secretId,
            secretKey: secretKey,
            token: Environment["TENCENTCLOUD_SESSIONTOKEN"]
        )
    }
}
