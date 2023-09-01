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
import struct Foundation.URL
import struct Foundation.URLComponents
import struct Foundation.URLQueryItem
import struct NIOHTTP1.HTTPHeaders
import enum NIOHTTP1.HTTPMethod
@_implementationOnly import struct Crypto.HMAC
@_implementationOnly import enum Crypto.Insecure
@_implementationOnly import struct Crypto.SymmetricKey

/// Tencent Cloud COS V5 API signer (HMAC-SHA1).
public struct COSSignerV5: _SignerSendable {
    /// Security credential for accessing Tencent Cloud services.
    public let credential: Credential

    /// Initialize the signer with Tencent Cloud credential.
    public init(credential: Credential) {
        self.credential = credential
    }

    // - MARK: Sign with URL (Convenient)

    /// Generate the signed URL for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL string (RFC 3986).
    ///   - method: Request HTTP method. Defaults to `.GET`.
    ///   - headers: Request HTTP headers.
    ///   - tokenKey: Key for specifying the session token. Defaults to `x-cos-security-token`.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for. Defaults to 10 minutes.
    /// - Returns: Signed request URL that contains the signature in query parameters.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signURL(
        url: String,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = HTTPHeaders(),
        tokenKey: String = "x-cos-security-token",
        date: Date = Date(),
        duration: TimeInterval = 600
    ) throws -> URL {
        guard var url = URLComponents(string: url) else {
            throw TCSignerError.invalidURL
        }
        url.percentEncodedQueryItems = self.signParameters(method: method, headers: headers, path: url.path, parameters: url.queryItems, tokenKey: tokenKey, date: date, duration: duration)
        guard let url = url.url else {
            throw TCSignerError.invalidURL
        }
        return url
    }

    /// Generate the signed URL for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - method: Request HTTP method. Defaults to `.GET`.
    ///   - headers: Request HTTP headers.
    ///   - tokenKey: Key for specifying the session token. Defaults to `x-cos-security-token`.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for. Defaults to 10 minutes.
    /// - Returns: Signed request URL that contains the signature in query parameters.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signURL(
        url: URL,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = HTTPHeaders(),
        tokenKey: String = "x-cos-security-token",
        date: Date = Date(),
        duration: TimeInterval = 600
    ) throws -> URL {
        guard var url = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TCSignerError.invalidURL
        }
        url.percentEncodedQueryItems = self.signParameters(method: method, headers: headers, path: url.path, parameters: url.queryItems, tokenKey: tokenKey, date: date, duration: duration)
        guard let url = url.url else {
            throw TCSignerError.invalidURL
        }
        return url
    }

    /// Generate signed headers for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL string (RFC 3986).
    ///   - method: Request HTTP method. Defaults to `.PUT`.
    ///   - headers: Request HTTP headers.
    ///   - tokenKey: Key for specifying the session token. Defaults to `x-cos-security-token`.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for. Defaults to 10 minutes.
    /// - Returns: Request headers with added "Authorization" header that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signHeaders(
        url: String,
        method: HTTPMethod = .PUT,
        headers: HTTPHeaders = HTTPHeaders(),
        tokenKey: String = "x-cos-security-token",
        date: Date = Date(),
        duration: TimeInterval = 600
    ) throws -> HTTPHeaders {
        guard let url = URLComponents(string: url) else {
            throw TCSignerError.invalidURL
        }
        return self.signHeaders(method: method, headers: headers, path: url.path, parameters: url.queryItems, tokenKey: tokenKey, date: date, duration: duration)
    }

    /// Generate signed headers for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - method: Request HTTP method. Defaults to `.PUT`.
    ///   - headers: Request HTTP headers.
    ///   - tokenKey: Key for specifying the session token. Defaults to `x-cos-security-token`.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for. Defaults to 10 minutes.
    /// - Returns: Request headers with added "Authorization" header that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signHeaders(
        url: URL,
        method: HTTPMethod = .PUT,
        headers: HTTPHeaders = HTTPHeaders(),
        tokenKey: String = "x-cos-security-token",
        date: Date = Date(),
        duration: TimeInterval = 600
    ) throws -> HTTPHeaders {
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TCSignerError.invalidURL
        }
        return self.signHeaders(method: method, headers: headers, path: url.path, parameters: url.queryItems, tokenKey: tokenKey, date: date, duration: duration)
    }

    // - MARK: Sign with host, path and query (Non-throwing)

    /// Generate signed query items for an HTTP request.
    ///
    /// - Parameters:
    ///   - method: Request HTTP method. Defaults to `.GET`.
    ///   - headers: Request HTTP headers.
    ///   - path: Request URL path.
    ///   - parameters: Request query items.
    ///   - tokenKey: Key for specifying the session token. Defaults to `x-cos-security-token`.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for. Defaults to 10 minutes.
    /// - Returns: Query items with the request signature added, properly encoded according to RFC 3986.
    public func signParameters(
        method: HTTPMethod = .GET,
        headers: HTTPHeaders = HTTPHeaders(),
        path: String,
        parameters: [URLQueryItem]? = nil,
        tokenKey: String = "x-cos-security-token",
        date: Date = Date(),
        duration: TimeInterval = 600
    ) -> [URLQueryItem] {
        var parameters = parameters ?? []

        // clean up signature-related parameters
        parameters.remove(name: "q-sign-algorithm")
        parameters.remove(name: "q-ak")
        parameters.remove(name: "q-sign-time")
        parameters.remove(name: "q-key-time")
        parameters.remove(name: "q-header-list")
        parameters.remove(name: "q-url-param-list")
        parameters.remove(name: "q-signature")
        parameters.remove(name: tokenKey)

        // compute and add the signature fragments
        parameters += self.signRequest(method: method, headers: headers, path: path, parameters: parameters, date: date, duration: duration)

        // now we have signed the request we can add the security token if supplied
        if let token = credential.token {
            parameters.replaceOrAdd(name: tokenKey, value: token)
        }
        return parameters.rfc3986Encoded()
    }

    /// Generate signed headers for an HTTP request.
    ///
    /// - Parameters:
    ///   - method: Request HTTP method. Defaults to `.PUT`.
    ///   - headers: Request HTTP headers.
    ///   - path: Request URL path.
    ///   - parameters: Request query items.
    ///   - tokenKey: Key for specifying the session token. Defaults to `x-cos-security-token`.
    ///   - date: Date that the signature is valid from, defaults to now.
    ///   - duration: Length of time that the signature is valid for. Defaults to 10 minutes.
    /// - Returns: Request headers with added "Authorization" header that contains request signature.
    public func signHeaders(
        method: HTTPMethod = .PUT,
        headers: HTTPHeaders = HTTPHeaders(),
        path: String,
        parameters: [URLQueryItem]? = nil,
        tokenKey: String = "x-cos-security-token",
        date: Date = Date(),
        duration: TimeInterval = 600
    ) -> HTTPHeaders {
        var headers = headers

        // clean up signature-related headers
        headers.remove(name: "authorization")
        headers.remove(name: tokenKey)

        // compute and use the signature as Authorization header
        let signature = self.signRequest(method: method, headers: headers, path: path, parameters: parameters, date: date, duration: duration)
        headers.replaceOrAdd(name: "authorization", value: signature.canonicalString())

        // now we have signed the request we can add the security token if supplied
        if let token = credential.token {
            headers.replaceOrAdd(name: tokenKey, value: token)
        }
        return headers
    }

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

extension COSSignerV5 {
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
