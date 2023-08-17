//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AsyncHTTPClient
import Logging
import NIOCore
import NIOHTTP1

extension AsyncHTTPClient.HTTPClient {
    /// Execute HTTP request.
    /// 
    /// - Parameters:
    ///   - request: HTTP request.
    ///   - timeout: If execution is idle for longer than timeout then throw error.
    ///   - eventLoop: `EventLoop` to run request on.
    /// - Returns: `EventLoopFuture` that will be fulfilled with request response.
    internal func execute(
        request: TCHTTPRequest,
        timeout: TimeAmount,
        on eventLoop: EventLoop,
        logger: Logger
    ) -> EventLoopFuture<TCResponse> {
        let requestBody: HTTPClient.Body?

        switch request.body.payload {
        case .byteBuffer(let byteBuffer):
            requestBody = .byteBuffer(byteBuffer)
        case .empty:
            requestBody = nil
        }

        do {
            let request = try HTTPClient.Request(
                url: request.url,
                method: request.method,
                headers: request.headers,
                body: requestBody
            )
            return self.execute(
                request: request,
                timeout: timeout,
                on: eventLoop,
                logger: logger
            ).flatMapThrowing { response in
                try TCResponse(status: response.status, headers: response.headers, body: response.body)
            }
        } catch {
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }

    /// Execute arbitrary HTTP request within specified timeout.
    ///
    /// - Parameters:
    ///   - request: HTTP request to execute.
    ///   - timeout: If execution is idle for longer than timeout then throw error.
    ///   - eventLoop: `EventLoop` to run request on.
    ///   - logger: The logger to use for this request.
    internal func execute(
        request: Request,
        timeout: TimeAmount,
        on eventLoop: EventLoop,
        logger: Logger? = nil
    ) -> EventLoopFuture<HTTPClient.Response> {
        self.execute(
            request: request,
            eventLoop: .delegate(on: eventLoop),
            deadline: .now() + timeout,
            logger: logger
        )
    }
}
