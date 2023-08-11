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

#if compiler(>=5.6)
public typealias _TecoSendable = Sendable
@preconcurrency public protocol _TecoPreconcurrencySendable: Sendable {}
#else
public typealias _TecoSendable = Any
public protocol _TecoPreconcurrencySendable {}
#endif
