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
    /// Execute a series of paginated requests and return a future with the combined result generated from the responses.
    ///
    /// - Parameters:
    ///   - input: Initial API request payload.
    ///   - region: Region of the service to operate on.
    ///   - command: Command to be paginated.
    ///   - initialValue: The value to use as the initial accumulating value.
    ///   - reducer: Function to combine responses into result value. This combined result is returned along with a boolean indicating if the pagination should continue.
    ///   - logger: Logger to log request details to.
    ///   - eventLoop: `EventLoop` to run request on.
    /// - Returns: ``EventLoopFuture`` containing the combined result.
    public func paginate<Result, Input: TCPaginatedRequest, Output: TCPaginatedResponse>(
        input: Input,
        region: TCRegion? = nil,
        command: @escaping (Input, TCRegion?, Logger, EventLoop?) -> EventLoopFuture<Output>,
        initialValue: Result,
        reducer: @escaping (Result, Output, EventLoop) -> EventLoopFuture<(Bool, Result)>,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<Result> where Input.Response == Output {
        let eventLoop = eventLoop ?? eventLoopGroup.next()
        let promise = eventLoop.makePromise(of: Result.self)

        func paginatePart(_ id: Int, input: Input, result: Result, recordedCount: Output.Count? = nil) {
            let responseFuture = command(input, region, logger.attachingPaginationContext(id: id), eventLoop)
                .flatMapWithEventLoop { response, eventLoop in
                    reducer(result, response, eventLoop).map { (continuePagination, result) -> Void in
                        guard continuePagination, let input = input.getNextPaginatedRequest(with: response) else {
                            return promise.succeed(result)
                        }
                        let totalCount = response.getTotalCount()
                        if let totalCount = totalCount, let recordedCount = recordedCount {
                            guard totalCount == recordedCount else {
                                return promise.fail(PaginationError.totalCountChanged)
                            }
                        }
                        paginatePart(id + 1, input: input, result: result, recordedCount: totalCount)
                    }
                }
            responseFuture.whenFailure { error in
                promise.fail(error)
            }
        }
        paginatePart(0, input: input, result: initialValue)

        return promise.futureResult.map { $0 }
    }

    /// Execute a series of paginated requests and return a future with total item count and complete output object list generated from the responses.
    ///
    /// - Parameters:
    ///   - input: Initial API request payload.
    ///   - region: Region of the service to operate on.
    ///   - command: Command to be paginated.
    ///   - logger: Logger to log request details to.
    ///   - eventLoop: `EventLoop` to run request on.
    /// - Returns: ``EventLoopFuture`` containing total item count and complete output object list from a series of requests.
    public func paginate<Input: TCPaginatedRequest, Output: TCPaginatedResponse>(
        input: Input,
        region: TCRegion? = nil,
        command: @escaping (Input, TCRegion?, Logger, EventLoop?) -> EventLoopFuture<Output>,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<(Output.Count?, [Output.Item])> where Input.Response == Output, Output.Count: BinaryInteger {
        self.paginate(
            input: input,
            region: region,
            command: command,
            initialValue: (nil, []),
            reducer: { result, response, eventLoop in
                let result = (result.0 ?? response.getTotalCount(), result.1 + response.getItems())
                return eventLoop.makeSucceededFuture((true, result))
            },
            logger: logger,
            on: eventLoop
        )
    }

    /// Execute a series of paginated requests and return a future with complete output object list generated from the responses.
    ///
    /// - Parameters:
    ///   - input: Initial API request payload.
    ///   - region: Region of the service to operate on.
    ///   - command: Command to be paginated.
    ///   - logger: Logger to log request details to.
    ///   - eventLoop: `EventLoop` to run request on.
    /// - Returns: ``EventLoopFuture`` containing the complete output object list from a series of requests.
    public func paginate<Input: TCPaginatedRequest, Output: TCPaginatedResponse>(
        input: Input,
        region: TCRegion? = nil,
        command: @escaping (Input, TCRegion?, Logger, EventLoop?) -> EventLoopFuture<Output>,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<[Output.Item]> where Input.Response == Output, Output.Count == Never {
        self.paginate(
            input: input,
            region: region,
            command: command,
            initialValue: [],
            reducer: { result, response, eventLoop in
                eventLoop.makeSucceededFuture((true, result + response.getItems()))
            },
            logger: logger,
            on: eventLoop
        )
    }

    /// Execute a series of paginated requests with callback for the responses.
    ///
    /// - Parameters:
    ///   - input: Initial API request payload.
    ///   - region: Region of the service to operate on.
    ///   - command: Command to be paginated.
    ///   - callback: Callback to run on every response. The return value indicates if the pagination should continue.
    ///   - logger: Logger to log request details to.
    ///   - eventLoop: `EventLoop` to run request on.
    public func paginate<Input: TCPaginatedRequest, Output: TCPaginatedResponse>(
        input: Input,
        region: TCRegion? = nil,
        command: @escaping (Input, TCRegion?, Logger, EventLoop?) -> EventLoopFuture<Output>,
        callback: @escaping (Output, EventLoop) -> EventLoopFuture<Bool>,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<Void> where Input.Response == Output {
        self.paginate(
            input: input,
            region: region,
            command: command,
            initialValue: (),
            reducer: { _, response, eventLoop in
                callback(response, eventLoop).map { ($0, ()) }
            },
            logger: logger,
            on: eventLoop
        )
    }
}

extension Logger {
    fileprivate func attachingPaginationContext(id: Int) -> Logger {
        var logger = self
        logger[metadataKey: "tc-client-pagination-seq"] = "\(id)"
        return logger
    }
}
