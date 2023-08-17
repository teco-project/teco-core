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

extension TCSigner {
    /// Process URL before signing.
    @available(*, deprecated, message: "Make sure the URL is RFC3986 compatible instead.")
    public func processURL(url: URL) -> URL? { url }
}
