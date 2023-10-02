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

@_exported import TecoCore

#if swift(>=5.6)
public typealias _PaginationSendable = Sendable
#else
public typealias _PaginationSendable = Any
#endif
