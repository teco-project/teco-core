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
// This source file is part of the Soto for AWS open source project
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

import class Foundation.JSONEncoder
import NIOCore
import NIOFoundationCompat

extension TCEncodableData {
    /// Encode TCDataType as JSON
    func encodeAsJSON(byteBufferAllocator: ByteBufferAllocator) throws -> ByteBuffer {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encodeAsByteBuffer(self, allocator: byteBufferAllocator)
    }

    /// Encode TCDataType as a query array
    func encodeAsQuery(with keys: [String: String]) throws -> String? {
        var encoder = QueryEncoder()
        encoder.additionalKeys = keys
        return try encoder.encode(self)
    }
}
