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
//
// This source file was part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import struct Foundation.Data
import class Foundation.JSONDecoder
import Logging
import NIOCore
import NIOFoundationCompat
import NIOHTTP1

/// Structure encapsulating a processed HTTP Response.
struct TCHTTPResponse {
    /// Response status.
    private let status: HTTPResponseStatus
    /// Response headers.
    private var headers: HTTPHeaders
    /// Response body.
    private let body: ByteBuffer?

    /// Initialize a ``TCHTTPResponse`` object.
    ///
    /// - Parameters:
    ///    - status: HTTP response status.
    ///    - headers: HTTP response headers.
    ///    - body: HTTP response body.
    internal init(status: HTTPResponseStatus, headers: HTTPHeaders, body: ByteBuffer?) throws {
        // Tencent Cloud API returns 200 even for API error, so treat any other response status as raw error
        guard status == .ok else {
            let context = TCErrorContext(message: "Unhandled Error", responseCode: status, headers: headers)
            guard var body = body else {
                throw TCRawError(context: context)
            }
            throw TCRawError(rawBody: body.readString(length: body.readableBytes), context: context)
        }

        // save HTTP context
        self.status = status
        self.headers = headers

        // handle empty response body
        guard let body = body, body.readableBytes > 0 else {
            self.body = nil
            return
        }

        // Tencent Cloud API response should always be JSON
        self.body = body
    }

    /// Generate ``TCModel`` from ``TCHTTPResponse``.
    internal func generateOutputData<Output: TCResponseModel>(
        errorType: TCErrorType.Type? = nil,
        errorLogLevel: Logger.Level = .info,
        logger: Logger
    ) throws -> Output {
        do {
            let container = try JSONDecoder().decode(Container<Output>.self, from: body ?? .init())
            return container.response
        } catch let apiError as APIError {
            let error = apiError.error
            logger.log(level: errorLogLevel, "Tencent Cloud service error", metadata: [
                "tc-error-code": .string(error.code),
                "tc-error-message": .string(error.message),
            ])

            let context = TCErrorContext(
                requestId: apiError.requestId,
                message: error.message,
                responseCode: self.status,
                headers: self.headers
            )

            if let errorType = errorType {
                for errorDomain in errorType.domains {
                    if let error = errorDomain.init(errorCode: error.code, context: context) {
                        throw error
                    }
                }
                if let error = errorType.init(errorCode: error.code, context: context) {
                    throw error
                }
            }

            if let error = TCCommonError(errorCode: error.code, context: context) {
                throw error
            }

            throw TCRawServiceError(errorCode: error.code, context: context)
        }
    }
}

extension TCHTTPResponse {
    /// Container that holds an API response.
    private struct Container<Output: TCResponseModel>: Decodable {
        let response: Output

        enum CodingKeys: String, CodingKey {
            case response = "Response"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let error = try? container.decode(APIError.self, forKey: .response) {
                throw error
            }
            self.response = try container.decode(Output.self, forKey: .response)
        }
    }

    /// Error payload used in JSON output.
    private struct APIError: TCResponseModel, Error {
        let error: Error
        let requestId: String

        struct Error: TCOutputModel {
            let code: String
            let message: String
            
            enum CodingKeys: String, CodingKey {
                case code = "Code"
                case message = "Message"
            }
        }

        enum CodingKeys: String, CodingKey {
            case error = "Error"
            case requestId = "RequestId"
        }
    }
}
