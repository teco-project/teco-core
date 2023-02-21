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

import NIOCore
import Logging
import TecoCore

extension TCClient {
    /// Execute a series of request for paginated results.
    ///
    /// - Parameters:
    ///   - input: Initial API request payload.
    ///   - region: Region of the service to operate on.
    ///   - command: Command to be paginated.
    ///   - logger: Logger to log request details to.
    ///   - eventLoop: `EventLoop` to run request on.
    /// - Returns: ``EventLoopFuture`` containing the total count and complete output object list from a series of requests.
    public func paginate<Input: TCPaginatedRequest, Output: TCPaginatedResponse, Item: Sendable, Count: Equatable>(
        input: Input,
        region: TCRegion? = nil,
        command: @escaping (Input, TCRegion?, Logger, EventLoop?) -> EventLoopFuture<Output>,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<(totalCount: Count?, result: [Item])> where Input.Response == Output, Output.Item == Item, Output.Count == Count {
        let eventLoop = eventLoop ?? eventLoopGroup.next()
        let promise = eventLoop.makePromise(of: (Count?, [Item]).self)

        func paginatePart(_ id: Int, input: Input, result: [Item], recordedCount: Count? = nil) {
            let responseFuture = command(input, region, logger.attachingPaginationContext(id: id), eventLoop)
                .map { response -> Void in
                    let items = response.getItems()
                    guard !items.isEmpty, let input = input.getNextPaginatedRequest(with: response) else {
                        return promise.succeed((recordedCount, result))
                    }
                    let totalCount = response.getTotalCount()
                    if let totalCount = totalCount, let recordedCount = recordedCount {
                        guard totalCount == recordedCount else {
                            return promise.fail(PaginationError.totalCountChanged)
                        }
                    }
                    paginatePart(id + 1, input: input, result: result + items, recordedCount: totalCount)
                }
            responseFuture.whenFailure { error in
                promise.fail(error)
            }
        }
        paginatePart(0, input: input, result: [])

        return promise.futureResult.map { $0 }
    }
}

extension Logger {
    fileprivate func attachingPaginationContext(id: Int) -> Logger {
        var logger = self
        logger[metadataKey: "tc-client-pagination-seq"] = "\(id)"
        return logger
    }
}
