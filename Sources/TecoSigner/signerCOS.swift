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

import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Foundation.URLQueryItem
import struct NIOHTTP1.HTTPHeaders
import enum NIOHTTP1.HTTPMethod
@_implementationOnly import struct Crypto.HMAC
@_implementationOnly import enum Crypto.Insecure
@_implementationOnly import struct Crypto.SymmetricKey

/// Tencent Cloud COS XML API signer (HMAC-SHA1).
public struct COSSigner: _SignerSendable {
    /// Security credential for accessing Tencent Cloud services.
    public let credential: Credential

    /// Initialize the signer with Tencent Cloud credential.
    public init(credential: Credential) {
        self.credential = credential
    }

    // - MARK: Sign with host, path and query (Non-throwing)

    /// Generate signature items for an HTTP request.
    ///
    /// - Parameters:
    ///   - method: Request HTTP method.
    ///   - headers: Request HTTP headers.
    ///   - path: Request URL path.
    ///   - parameters: Request query items.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for.
    /// - Returns: A list of query items that form a valid signature for the request.
    public func signRequest(
        method: HTTPMethod,
        headers: HTTPHeaders,
        path: String,
        parameters: [URLQueryItem]?,
        date: Date = Date(),
        duration: TimeInterval
    ) -> [URLQueryItem] {
        var authorization = [
            URLQueryItem(name: "q-sign-algorithm", value: "sha1"),
            URLQueryItem(name: "q-ak", value: credential.secretId),
        ]

        // construct signing data
        let signingData = SigningData(path: path, method: method, headers: headers, parameters: parameters, date: date, duration: duration)

        // add signature parameters
        authorization.replaceOrAdd(name: "q-sign-time", value: signingData.keyTime)
        authorization.replaceOrAdd(name: "q-key-time", value: signingData.keyTime)
        authorization.replaceOrAdd(name: "q-header-list", value: signingData.headerList)
        authorization.replaceOrAdd(name: "q-url-param-list", value: signingData.parameterList)

        // compute signature for request
        authorization.replaceOrAdd(name: "q-signature", value: signature(signingData: signingData))

        return authorization
    }
}

extension COSSigner {
    /// structure used to store data used throughout the signing process
    struct SigningData {
        let keyTime: String
        let path: String
        let method: HTTPMethod
        let headers: [URLQueryItem]
        let headerList: String
        let parameters: [URLQueryItem]
        let parameterList: String

        init(path: String, method: HTTPMethod, headers: HTTPHeaders, parameters: [URLQueryItem]?, date: Date, duration: TimeInterval) {
            self.keyTime = "\(date.timestamp);\(date.addingTimeInterval(duration).timestamp)"
            self.path = path.isEmpty ? "/" : path
            self.method = method

            self.headers = headers.map {
                URLQueryItem(name: $0.name, value: $0.value)
            }.rfc3986Encoded().map {
                URLQueryItem(name: $0.name.lowercased(), value: $0.value)
            }.sorted { $0.name < $1.name }
            self.headerList = self.headers.map(\.name).joined(separator: ";")

            if let parameters = parameters {
                self.parameters = parameters.rfc3986Encoded().map {
                    URLQueryItem(name: $0.name.lowercased(), value: $0.value)
                }.sorted { $0.name < $1.name }
            } else {
                self.parameters = []
            }
            self.parameterList = self.parameters.map(\.name).joined(separator: ";")
        }
    }

    /// Stage 3 Calculating signature as in https://www.tencentcloud.com/document/product/436/7778#step-7.-generate-signature
    func signature(signingData: SigningData) -> String {
        let signingSecret = signingSecret(keyTime: signingData.keyTime)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: [UInt8](stringToSign(signingData: signingData).utf8), using: signingSecret)
        return signature.hexDigest()
    }

    /// Stage 2 Create the string to sign as in https://www.tencentcloud.com/document/product/436/7778#step-6.-generate-stringtosign
    func stringToSign(signingData: SigningData) -> String {
        """
        sha1
        \(signingData.keyTime)
        \(Insecure.SHA1.hash(data: [UInt8](httpString(signingData: signingData).utf8)).hexDigest())
        
        """
    }

    /// Stage 1 Create the canonical request as in https://www.tencentcloud.com/document/product/436/7778#step-5.-generate-httpstring
    func httpString(signingData: SigningData) -> String {
        """
        \(signingData.method.rawValue.lowercased())
        \(signingData.path)
        \(signingData.parameters.canonicalString())
        \(signingData.headers.canonicalString())
        
        """
    }

    /// Compute signing key.
    func signingSecret(keyTime: String) -> SymmetricKey {
        let secretKeyTime = HMAC<Insecure.SHA1>.authenticationCode(for: [UInt8](keyTime.utf8), using: SymmetricKey(data: [UInt8](credential.secretKey.utf8)))
        return SymmetricKey(data: [UInt8](secretKeyTime.hexDigest().utf8))
    }
}
