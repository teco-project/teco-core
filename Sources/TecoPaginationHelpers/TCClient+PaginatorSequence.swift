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
    /// Used to access paginated API responses.
    public struct PaginatorSequence<Input: TCPaginatedRequest, Output: TCPaginatedResponse>: AsyncSequence where Input.Response == Output {
        public typealias Element = Output
        let input: Input
        let region: TCRegion?
        let command: (Input, TCRegion?, Logger, EventLoop?) async throws -> Output
        let logger: Logger
        let eventLoop: EventLoop?

        /// Initialize ``PaginatorSequence``.
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

        /// Iterator for iterating over ``PaginatorSequence``.
        public struct AsyncIterator: AsyncIteratorProtocol {
            var input: Input?
            var totalCount: Output.Count?
            let sequence: PaginatorSequence

            init(sequence: PaginatorSequence) {
                self.sequence = sequence
                self.totalCount = nil
                self.input = sequence.input
            }

            public mutating func next() async throws -> Output? {
                if let input = input {
                    // Execute the request and prepare for the next
                    let output = try await self.sequence.command(input, self.sequence.region, self.sequence.logger, self.sequence.eventLoop)
                    guard let nextInput = input.getNextPaginatedRequest(with: output) else {
                        self.input = nil
                        return output
                    }
                    self.input = nextInput
                    // Judge over total count
                    if let oldTotalCount = totalCount, let totalCount = output.getTotalCount() {
                        guard totalCount == oldTotalCount else {
                            throw PaginationError.totalCountChanged
                        }
                    } else {
                        self.totalCount = output.getTotalCount()
                    }
                    return output
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
