//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
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
import NIOHTTP1

/// Structure encapsulating a processed HTTP Response.
struct TCResponse {
    /// Response status.
    private let status: HTTPResponseStatus
    /// Response headers.
    private var headers: HTTPHeaders
    /// Response body.
    private let body: Body

    /// Initialize an ``TCResponse`` object.
    ///
    /// - Parameters:
    ///    - response: Raw HTTP response.
    internal init(from response: TCHTTPResponse) throws {
        self.status = response.status
        
        // headers
        self.headers = response.headers
        
        // handle empty body
        guard let body = response.body, body.readableBytes > 0 else {
            self.body = .empty
            return
        }
        
        // tencent cloud api response is always json
        self.body = .json(body)
    }

    /// Generate ``TCModel`` from ``TCResponse``.
    internal func generateOutputData<Output: TCResponseModel>(errorType: TCErrorType.Type? = nil, logLevel: Logger.Level = .info, logger: Logger) throws -> Output {
        let decoder = JSONDecoder()
        let data: Data?

        switch body {
        case .text(let string):
            data = string.data(using: .utf8)
        case .json(let buffer):
            data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes, byteTransferStrategy: .noCopy)
        default:
            data = nil
        }

        do {
            let container = try decoder.decode(Container<Output>.self, from: data ?? Data())
            return container.response
        } catch let apiError as APIError {
            let error = apiError.error
            logger.log(level: logLevel, "Tencent Cloud service error", metadata: [
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

extension TCResponse {
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
