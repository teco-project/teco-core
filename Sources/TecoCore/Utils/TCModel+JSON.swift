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

import class Foundation.JSONEncoder
import NIOCore

extension TCModel {
    /// Encode ``TCModel`` as JSON.
    func encodeAsJSON(byteBufferAllocator: ByteBufferAllocator) throws -> ByteBuffer {
        try JSONEncoder().encodeAsByteBuffer(self, allocator: byteBufferAllocator)
    }
}
