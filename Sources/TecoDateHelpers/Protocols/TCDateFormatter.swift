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

import struct Foundation.Date
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter

public protocol TCDateFormatter {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension Foundation.DateFormatter: TCDateFormatter {}
extension Foundation.ISO8601DateFormatter: TCDateFormatter {}
