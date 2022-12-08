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
    /// Construct static credentaisl from TCCLI-defined environment variables if it exists.
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
}
