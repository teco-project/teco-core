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
    /// Tuple consisting of async sequences returned by the paginator.
    public typealias PaginatorSequences<Input: TCPaginatedRequest> = (
        results: Paginator<Input, Input.Response>.ResultSequence,
        responses: Paginator<Input, Input.Response>.ResponseSequence
    )

    /// Helper namespace used to access paginated API results.
    public enum Paginator<Input: TCPaginatedRequest, Output: TCPaginatedResponse> where Input.Response == Output {
        /// Async sequence that returns paginated Tencent Cloud API responses.
        public struct ResponseSequence: AsyncSequence {
            public typealias Element = Output

            /// Initial API request payload.
            let input: Input
            /// Region of the service to operate on.
            let region: TCRegion?
            /// Teco command to be paginated.
            let command: (Input, TCRegion?, Logger, EventLoop?) async throws -> Output
            /// Logger to log request details to.
            let logger: Logger
            /// `EventLoop` to run request on.
            let eventLoop: EventLoop?

            /// Initialize ``ResponseSequence``.
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

            /// Iterator for iterating over ``ResponseSequence``.
            public struct AsyncIterator: AsyncIteratorProtocol {
                /// The next input for paginated API.
                var input: Input?
                /// Total count extracted from the paginated responses.
                var totalCount: Output.Count?
                /// Async sequence that holds this iterator.
                let sequence: ResponseSequence

                init(sequence: ResponseSequence) {
                    self.sequence = sequence
                    self.totalCount = nil
                    self.input = sequence.input
                }

                /// Returns the next pagninated response asynchronously.
                public mutating func next() async throws -> Output? {
                    if let input = input {
                        // Execute the request and prepare for the next
                        let output = try await self.sequence.command(input, self.sequence.region, self.sequence.logger, self.sequence.eventLoop)
                        guard let nextInput = input.makeNextRequest(with: output) else {
                            self.input = nil
                            return output
                        }
                        self.input = nextInput
                        // Judge over total count
                        if let oldTotalCount = totalCount, let totalCount = output.getTotalCount() {
                            guard totalCount == oldTotalCount else {
                                throw TCClient.PaginationError.totalCountChanged
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
                AsyncIterator(sequence: self)
            }
        }

        /// Async sequence that returns paginated Tencent Cloud API result items.
        public struct ResultSequence: AsyncSequence {
            public typealias Element = Output.Item

            /// Async sequence that returns paginated responses.
            let paginator: ResponseSequence

            fileprivate init(_ paginator: ResponseSequence) {
                self.paginator = paginator
            }

            /// Initialize ``ResultSequence``.
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
                self.paginator = ResponseSequence(input: input, region: region, command: command, logger: logger, on: eventLoop)
            }

            /// Iterator for iterating over ``ResultSequence``.
            public struct AsyncIterator: AsyncIteratorProtocol {
                /// Cached result queue that can be returned instantly.
                var queue: [Element]
                /// Async iterator for iterating over paginated responses.
                var iterator: ResponseSequence.AsyncIterator

                init(sequence: ResultSequence) {
                    self.queue = []
                    self.iterator = sequence.paginator.makeAsyncIterator()
                }

                /// Returns the next pagninated result item asynchronously.
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
                AsyncIterator(sequence: self)
            }
        }

        /// Returns async sequences containing results and responses from the input.
        ///
        /// - Parameters:
        ///   - input: Initial API request payload.
        ///   - region: Region of the service to operate on.
        ///   - command: Command to be paginated.
        ///   - logger: Logger to log request details to.
        ///   - eventLoop: `EventLoop` to run request on.
        public static func makeAsyncSequences(
            input: Input,
            region: TCRegion? = nil,
            command: @escaping (Input, TCRegion?, Logger, EventLoop?) async throws -> Output,
            logger: Logger = TCClient.loggingDisabled,
            on eventLoop: EventLoop? = nil
        ) -> PaginatorSequences<Input> {
            let responses = ResponseSequence(input: input, region: region, command: command, logger: logger, on: eventLoop)
            return (results: .init(responses), responses: responses)
        }
    }
}
