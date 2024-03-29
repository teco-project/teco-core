//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.URL

/// Tencent Cloud API V3 signer (TC3-HMAC-SHA256).
@available(*, deprecated, renamed: "TCSignerV3")
public typealias TCSigner = TCSignerV3

extension TCSignerV3 {
    /// Process URL before signing.
    @available(*, deprecated, message: "Make sure the URL is RFC3986 compatible instead.")
    public func processURL(url: URL) -> URL? { url }
}
