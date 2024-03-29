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
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public struct CredentialProviderError: Error, Equatable {
    private enum _Error {
        case noProvider
    }
    private let error: _Error

    /// No credential provider selected.
    public static var noProvider: CredentialProviderError { .init(error: .noProvider) }
}

extension CredentialProviderError: CustomStringConvertible {
    public var description: String {
        switch self.error {
        case .noProvider:
            return "No credential provider found"
        }
    }
}
