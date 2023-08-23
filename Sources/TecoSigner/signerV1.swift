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

import struct Foundation.CharacterSet
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

    // - MARK: Sign with URL (Defaults to `GET`)

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL string (RFC 3986).
    ///   - method: Request HTTP method. Defaults to`.GET`.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        url: String,
        method: HTTPMethod = .GET,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> String {
        guard let url = URLComponents(string: url), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        return self.signQueryString(host: host, path: url.path, queryItems: url.queryItems, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - method: Request HTTP method. Defaults to`.GET`.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        url: URL,
        method: HTTPMethod = .GET,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> String {
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        return self.signQueryString(host: host, path: url.path, queryItems: url.queryItems, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    // - MARK: Sign with URL and query (Defaults to `POST`)

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - query: Request query string.
    ///   - method: Request HTTP method. Defaults to`.POST`.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        url: String,
        query: String?,
        method: HTTPMethod = .POST,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> String {
        guard let url = URLComponents(string: url), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        return self.signQueryString(host: host, path: url.path, query: query, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - query: Request query string.
    ///   - method: Request HTTP method. Defaults to`.POST`.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        url: URL,
        query: String?,
        method: HTTPMethod = .POST,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> String {
        guard let host = url.host else {
            throw TCSignerError.invalidURL
        }
        return self.signQueryString(host: host, path: url.path, query: query, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - queryItems: Request query items.
    ///   - method: Request HTTP method. Defaults to`.POST`.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        url: String,
        queryItems: [URLQueryItem]?,
        method: HTTPMethod = .POST,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> String {
        guard let url = URLComponents(string: url), let host = url.host else {
            throw TCSignerError.invalidURL
        }
        return self.signQueryString(host: host, path: url.path, queryItems: queryItems, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - queryItems: Request query items.
    ///   - method: Request HTTP method. Defaults to`.POST`.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        url: URL,
        queryItems: [URLQueryItem]?,
        method: HTTPMethod = .POST,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) throws -> String {
        guard let host = url.host else {
            throw TCSignerError.invalidURL
        }
        return self.signQueryString(host: host, path: url.path, queryItems: queryItems, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    // - MARK: Sign with host, path and query (Non-throwing)

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - host: Request HTTP host.
    ///   - path: Request URL path.
    ///   - query: Request query string.
    ///   - method: Request HTTP method. Defaults to`.GET`.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        host: String,
        path: String = "/",
        query: String?,
        method: HTTPMethod = .GET,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) -> String {
        let queryItems: [URLQueryItem]? = {
            var url = URLComponents()
            url.query = query
            return url.queryItems
        }()
        return self.signQueryString(host: host, path: path, queryItems: queryItems, method: method, algorithm: algorithm, omitSessionToken: omitSessionToken, nonce: nonce, date: date)
    }

    /// Generate signed query string, for an HTTP request.
    ///
    /// - Parameters:
    ///   - host: Request HTTP host.
    ///   - path: Request URL path.
    ///   - queryItems: Request query items.
    ///   - method: Request HTTP method. Defaults to`.GET`.
    ///   - algorithm: Algorithm used for signing. Defaults to HmacSHA1.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - nonce: One-time unsigned integer that's used for anti-replay. Defaults to generate randomly.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Query string with added "Signature" field that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed.
    public func signQueryString(
        host: String,
        path: String = "/",
        queryItems: [URLQueryItem]?,
        method: HTTPMethod = .GET,
        algorithm: Algorithm = .hmacSHA1,
        omitSessionToken: Bool = false,
        nonce: UInt? = nil,
        date: Date = Date()
    ) -> String {
        var queryItems = queryItems ?? []
        queryItems.remove(name: "Signature")

        // set timestamp and nonce
        queryItems.replaceOrAdd(name: "Timestamp", value: TCSignerV1.timestamp(date))
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

        // compose query items into string
        return TCSignerV1.percentEncodedQuery(queryItems)
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
        return queryItems
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&")
    }

    /// return a timestamp formatted for signing requests
    static func timestamp(_ date: Date) -> String {
        String(UInt64(date.timeIntervalSince1970))
    }

    /// return a random unsigned integer for request nonce
    static func nonce() -> String {
        String(Int32.random(in: 0...Int32.max))
    }

    /// return the query string that is percent encoded properly
    static func percentEncodedQuery(_ queryItems: [URLQueryItem]) -> String {
        queryItems.sorted(by: { $0.name < $1.name })
            .map { "\($0.name)=\($0.value?.queryValueEncoded() ?? "")" }
            .joined(separator: "&")
    }
}

private extension CharacterSet {
    static let tcQueryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(.init(charactersIn: "/;+=&"))
}

private extension String {
    func queryValueEncoded() -> String {
        self.addingPercentEncoding(withAllowedCharacters: .tcQueryValueAllowed) ?? self
    }
}

private extension RangeReplaceableCollection where Self : MutableCollection, Element == URLQueryItem {
    mutating func replaceOrAdd(name: String, value: String?) {
        let queryItem = URLQueryItem(name: name, value: value)
        if let index = self.firstIndex(where: { $0.name == name }) {
            self[index] = queryItem
        } else {
            self.append(queryItem)
        }
    }
    mutating func remove(name: String) {
        self.removeAll(where: { $0.name == name })
    }
}
