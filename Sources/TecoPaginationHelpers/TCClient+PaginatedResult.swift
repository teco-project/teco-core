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

import Logging
import NIOCore
import TecoCore

extension TCClient {
    /// Used to access paginated results.
    public struct PaginatedResult<Input: TCPaginatedRequest, Output: TCPaginatedResponse>: AsyncSequence where Input.Response == Output {
        public typealias Element = Output.Item
        let input: Input
        let region: TCRegion?
        let command: (Input, TCRegion?, Logger, EventLoop?) async throws -> Output
        let logger: Logger
        let eventLoop: EventLoop?

        /// Initialize ``PaginatedResult``.
        ///
        /// - Parameters:
        ///   - input: Initial API request payload.
        ///   - region: Region of the service to operate on.
        ///   - command: Command to be paginated.
        ///   - logger: Logger to log request details to.
        ///   - eventLoop: `EventLoop` to run request on.
        public init(
            input: Input,
            region: TCRegion? = nil,
            command: @escaping (Input, TCRegion?, Logger, EventLoop?) async throws -> Output,
            logger: Logger = TCClient.loggingDisabled,
            on eventLoop: EventLoop? = nil
        ) {
            self.input = input
            self.region = region
            self.command = command
            self.logger = logger
            self.eventLoop = eventLoop
        }

        /// Iterator for iterating over ``PaginatedResult``.
        public struct AsyncIterator: AsyncIteratorProtocol {
            var input: Input?
            var queue: [Element]
            var totalCount: Output.Count?
            let sequence: PaginatedResult

            init(sequence: PaginatedResult) {
                self.sequence = sequence
                self.queue = []
                self.totalCount = nil
                self.input = sequence.input
            }

            public mutating func next() async throws -> Element? {
                // If there're elements left in the queue, return in sequence directly
                guard queue.isEmpty else {
                    return queue.removeFirst()
                }
                if let input = input {
                    // Get output
                    let output = try await self.sequence.command(input, self.sequence.region, self.sequence.logger, self.sequence.eventLoop)
                    let items = output.getItems()
                    // Judge over total count
                    if let oldTotalCount = totalCount, let totalCount = output.getTotalCount() {
                        guard items.isEmpty || totalCount == oldTotalCount else {
                            throw PaginationError.totalCountChanged
                        }
                    } else {
                        self.totalCount = output.getTotalCount()
                    }
                    // Prepare the input and queue
                    self.input = input.getNextPaginatedRequest(with: output)
                    self.queue += items.dropFirst()
                    return items.first
                }
                return nil
            }
        }

        /// Makes an ``AsyncIterator``.
        public func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(sequence: self)
        }
    }
}
