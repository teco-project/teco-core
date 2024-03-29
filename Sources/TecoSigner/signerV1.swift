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

import struct Foundation.Data
import struct Foundation.Date
import struct Foundation.URL
import struct Foundation.URLComponents
import struct Foundation.URLQueryItem
import enum NIOHTTP1.HTTPMethod
@_implementationOnly import protocol Crypto.HashFunction
@_implementationOnly import struct Crypto.HMAC
@_implementationOnly import enum Crypto.Insecure
@_implementationOnly import struct Crypto.SHA256
@_implementationOnly import struct Crypto.SymmetricKey

/// Tencent Cloud API V1 signer (HmacSHA1).
public struct TCSignerV1: _SignerSendable {
    /// Security credential for accessing Tencent Cloud services.
    public let credential: Credential

    /// Initialize the signer with Tencent Cloud credential.
    public init(credential: Credential) {
        self.credential = credential
    }

    /// Signing algorithm.
    public enum Algorithm: String, _SignerSendable {
        /// Use the `HmacSHA1` signing algorithm.
        case hmacSHA1 = "HmacSHA1"
        /// Use the `HmacSHA256` signing algorithm.
        case hmacSHA256 = "HmacSHA256"
    }

    // - MARK: Sign a `GET` request URL

    /// Generate the signed URL for an HTTP GET request.
    ///
    /// - Parameters:
    ///   - url: Request URL string (RFC 3986).
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Signed request URL that contains a "Signature" query parameter, encoded according to RFC 3986.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signURL(
        url: String,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> URL {
        guard var url = URLComponents(string: url), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        url.percentEncodedQueryItems = self.signQueryItems(host: host, path: url.path, queryItems: url.queryItems, method: .GET, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
            .rfc3986Encoded()
        guard let url = url.url else {
            throw TCSignerError.invalidURL
        }
        return url
    }

    /// Generate the signed URL for an HTTP GET request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Signed request URL that contains a "Signature" query parameter, encoded according to RFC 3986.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signURL(
        url: URL,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> URL {
        guard var url = URLComponents(url: url, resolvingAgainstBaseURL: false), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        url.percentEncodedQueryItems = self.signQueryItems(host: host, path: url.path, queryItems: url.queryItems, method: .GET, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
            .rfc3986Encoded()
        guard let url = url.url else {
            throw TCSignerError.invalidURL
        }
        return url
    }

    // - MARK: Sign a `POST` request body

    /// Generate the signed body for an HTTP POST request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - queryItems: Request query items.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Signed request body that contains a "Signature" query parameter, encoded according to `x-www-form-urlencoded`.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signBody(
        url: String,
        queryItems: [URLQueryItem]?,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> Data {
        guard let url = URLComponents(string: url), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        let bodyString = self.signQueryItems(host: host, path: url.path, queryItems: queryItems, method: .POST, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
            .wwwFormURLEncodedString()
        return .init([UInt8](bodyString.utf8))
    }

    /// Generate the signed body for an HTTP POST request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - queryItems: Request query items.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Signed request body that contains a "Signature" query parameter, encoded according to `x-www-form-urlencoded`.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is invalid according to RFC 3986.
    public func signBody(
        url: URL,
        queryItems: [URLQueryItem]?,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> Data {
        guard let host = url.host else {
            throw TCSignerError.invalidURL
        }
        let bodyString = self.signQueryItems(host: host, path: url.path, queryItems: queryItems, method: .POST, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
            .wwwFormURLEncodedString()
        return .init([UInt8](bodyString.utf8))
    }

    // - MARK: Sign with host, path and query (Non-throwing)

    /// Generate signed query items for an HTTP request.
    ///
    /// - Parameters:
    ///   - host: Request HTTP host.
    ///   - path: Request URL path.
    ///   - queryItems: Request query items.
    ///   - method: Request HTTP method.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query items with added "Signature" field that contains the request signature.
    public func signQueryItems(
        host: String,
        path: String = "/",
        queryItems: [URLQueryItem]?,
        method: HTTPMethod,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) -> [URLQueryItem] {
        var queryItems = queryItems ?? []
        queryItems.remove(name: "Signature")

        // set timestamp and nonce
        queryItems.replaceOrAdd(name: "Timestamp", value: date.timestamp)
        queryItems.replaceOrAdd(name: "Nonce", value: nonce.map(String.init) ?? TCSignerV1.nonce())

        // add "SecretId" field
        queryItems.replaceOrAdd(name: "SecretId", value: credential.secretId)

        // add "SignatureMethod" field
        if algorithm != .hmacSHA1 {
            queryItems.replaceOrAdd(name: "SignatureMethod", value: algorithm.rawValue)
        } else {
            queryItems.remove(name: "SignatureMethod")
        }

        // add session token if available
        if !omitSessionToken, let sessionToken = credential.token {
            queryItems.replaceOrAdd(name: "Token", value: sessionToken)
        } else {
            queryItems.remove(name: "Token")
        }

        // construct signing data. Do this after adding query items as it uses data from them
        let signingData = SigningData(host: host, path: path, queryItems: queryItems, method: method)

        // add "Signature" field
        switch algorithm {
        case .hmacSHA1:
            queryItems.replaceOrAdd(name: "Signature", value: signature(signingData: signingData, hashFunction: Insecure.SHA1.self))
        case .hmacSHA256:
            queryItems.replaceOrAdd(name: "Signature", value: signature(signingData: signingData, hashFunction: SHA256.self))
        }

        // now we have signed the request we can add the security token if required
        if omitSessionToken, let sessionToken = credential.token {
            queryItems.replaceOrAdd(name: "Token", value: sessionToken)
        }

        return queryItems.sorted(by: { $0.name < $1.name })
    }
}

extension TCSignerV1 {
    /// structure used to store data used throughout the signing process
    struct SigningData {
        let host: String
        let path: String
        let queryItems: [URLQueryItem]
        let method: HTTPMethod

        init(host: String?, path: String, queryItems: [URLQueryItem]?, method: HTTPMethod) {
            self.host = host ?? ""
            self.path = path.isEmpty ? "/" : path
            self.queryItems = queryItems ?? []
            self.method = method
        }
    }

    /// Stage 3 Calculating signature as in https://www.tencentcloud.com/document/api/213/31575#2.4.-generating-a-signature-string
    func signature<H: HashFunction>(signingData: SigningData, hashFunction: H.Type) -> String {
        let signingSecret = SymmetricKey(data: [UInt8](credential.secretKey.utf8))
        let signature = HMAC<H>.authenticationCode(for: [UInt8](signatureOriginalString(signingData: signingData).utf8), using: signingSecret)
        return Data(signature).base64EncodedString()
    }

    /// Stage 2 Create the signature original string as in https://www.tencentcloud.com/document/api/213/31575#2.3.-concatenating-the-signature-original-string
    func signatureOriginalString(signingData: SigningData) -> String {
        signingData.method.rawValue + signingData.host + signingData.path + "?" + requestString(items: signingData.queryItems)
    }

    /// Stage 1 Create the request string as in https://www.tencentcloud.com/document/api/213/31575#2.1.-sorting-parameters and https://www.tencentcloud.com/document/api/213/31575#2.2.-concatenating-a-request-string
    func requestString(items: [URLQueryItem]) -> String {
        let queryItems = items.sorted { $0.name < $1.name }
        return queryItems.canonicalString()
    }

    /// return a random unsigned integer for request nonce
    static func nonce() -> String {
        String(Int32.random(in: 0...Int32.max))
    }
}
