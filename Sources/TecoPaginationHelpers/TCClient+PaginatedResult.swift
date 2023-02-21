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
    /// Used to access paginated API results.
    public struct PaginatedResult<Input: TCPaginatedRequest, Output: TCPaginatedResponse>: AsyncSequence where Input.Response == Output {
        public typealias Element = Output.Item
        let paginator: PaginatorSequence<Input, Output>

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
            self.paginator = PaginatorSequence(input: input, region: region, command: command, logger: logger, on: eventLoop)
        }

        /// Iterator for iterating over ``PaginatedResult``.
        public struct AsyncIterator: AsyncIteratorProtocol {
            var queue: [Element]
            var iterator: PaginatorSequence<Input, Output>.AsyncIterator

            init(sequence: PaginatedResult) {
                self.queue = []
                self.iterator = sequence.paginator.makeAsyncIterator()
            }

            public mutating func next() async throws -> Element? {
                // If there're elements left in the queue, return in sequence directly
                guard queue.isEmpty else {
                    return queue.removeFirst()
                }
                // If the response stream is ended, return nil
                guard let response = try await iterator.next() else {
                    return nil
                }
                // Returns the first element from response
                let items = response.getItems()
                self.queue += items.dropFirst()
                return items.first
            }
        }

        /// Makes an ``AsyncIterator``.
        public func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(sequence: self)
        }
    }
}
