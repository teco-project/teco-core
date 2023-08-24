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
// Copyright (c) 2017-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if os(Linux) && compiler(>=5.6)
@preconcurrency import struct Foundation.Data
#else
import struct Foundation.Data
#endif
import struct Foundation.CharacterSet
import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeZone
import struct Foundation.URL
import struct Foundation.URLComponents
import struct Foundation.URLQueryItem
import struct NIOCore.ByteBuffer
import struct NIOHTTP1.HTTPHeaders
import enum NIOHTTP1.HTTPMethod
@_implementationOnly import struct Crypto.HMAC
@_implementationOnly import struct Crypto.SHA256
@_implementationOnly import struct Crypto.SymmetricKey

/// Tencent Cloud API V3 signer (TC3-HMAC-SHA256).
public struct TCSignerV3: _SignerSendable {
    /// Security credential for accessing Tencent Cloud services.
    public let credential: Credential
    /// Service name you're requesting for.
    public let service: String

    static let hashedEmptyBody = SHA256.hash(data: [UInt8]()).hexDigest()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Initialize the signer with Tencent Cloud credential.
    public init(credential: Credential, service: String) {
        self.credential = credential
        self.service = service
    }

    /// Enumeration for holding request payload.
    public enum BodyData: _SignerSendable {
        /// String.
        case string(String)
        /// Data.
        case data(Data)
        /// Byte buffer from NIO.
        case byteBuffer(ByteBuffer)
        /// Don't use body when signing request.
        case unsignedPayload
    }

    /// Signing mode configuration.
    public enum SigningMode: _SignerSendable {
        /// Use the maximal available headers for signature.
        case `default`
        /// Use the minimal required headers for signature.
        case minimal
        /// Set "Authorization" header to `SKIP` without actually performing the sign.
        case skip
    }

    /// Generate signed headers, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL string (RFC 3986).
    ///   - method: Request HTTP method. Defaults to`.POST`.
    ///   - headers: Request headers.
    ///   - body: Request body.
    ///   - mode: Signing mode.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Request headers with added "Authorization" header that contains request signature.
    /// - Throws: `TCSignerError.invalidURL` if the URL string is malformed (eg. not conforms to RFC 3986).
    public func signHeaders(
        url: String,
        method: HTTPMethod = .POST,
        headers: HTTPHeaders = HTTPHeaders(),
        body: BodyData? = nil,
        mode: SigningMode = .default,
        omitSessionToken: Bool = false,
        date: Date = Date()
    ) throws -> HTTPHeaders {
        guard let url = URLComponents(string: url) else {
            throw TCSignerError.invalidURL
        }
        return self.signHeaders(url: url, method: method, headers: headers, body: body, mode: mode, omitSessionToken: omitSessionToken, date: date)
    }

    /// Generate signed headers, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - method: Request HTTP method. Defaults to`.POST`.
    ///   - headers: Request headers.
    ///   - body: Request body.
    ///   - mode: Signing mode.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Request headers with added "Authorization" header that contains request signature.
    public func signHeaders(
        url: URL,
        method: HTTPMethod = .POST,
        headers: HTTPHeaders = HTTPHeaders(),
        body: BodyData? = nil,
        mode: SigningMode = .default,
        omitSessionToken: Bool = false,
        date: Date = Date()
    ) /*throws*/ -> HTTPHeaders {
        // FIXME: This function should be throwing, but changing it requires major version bump.
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            // throw TCSignerError.invalidURL
            fatalError("Invalid URL provided, please ensure RFC 3986 encoding: \(url)")
        }
        return self.signHeaders(url: url, method: method, headers: headers, body: body, mode: mode, omitSessionToken: omitSessionToken, date: date)
    }

    /// Generate signed headers, for an HTTP request.
    ///
    /// - Parameters:
    ///   - url: Request URL (RFC 3986).
    ///   - method: Request HTTP method.
    ///   - headers: Request headers.
    ///   - body: Request body.
    ///   - mode: Signing mode.
    ///   - omitSessionToken: Should we include security token in the canonical headers.
    ///   - date: Date that URL is valid from, defaults to now.
    /// - Returns: Request headers with added "Authorization" header that contains request signature.
    public func signHeaders(
        url: URLComponents,
        method: HTTPMethod,
        headers: HTTPHeaders,
        body: BodyData?,
        mode: SigningMode = .default,
        omitSessionToken: Bool = false,
        date: Date = Date()
    ) -> HTTPHeaders {
        var headers = headers

        // compute required values for signing
        let bodyHash = TCSignerV3.hashedPayload(body)
        let timestamp = TCSignerV3.timestamp(date)
        let dateString = TCSignerV3.dateString(date)

        // add timestamp, host and body hash to headers
        headers.replaceOrAdd(name: "host", value: TCSignerV3.hostname(from: url))
        headers.replaceOrAdd(name: "x-tc-requestclient", value: "Teco")
        headers.replaceOrAdd(name: "x-tc-timestamp", value: timestamp)
        headers.replaceOrAdd(name: "x-tc-content-sha256", value: bodyHash)

        // set authorization to SKIP without actually signing if requested
        if mode == .skip {
            headers.replaceOrAdd(name: "authorization", value: "SKIP")
            return headers
        }

        // add session token if available
        if !omitSessionToken, let sessionToken = credential.token {
            headers.replaceOrAdd(name: "x-tc-token", value: sessionToken)
        } else {
            headers.remove(name: "x-tc-token")
        }

        // construct signing data. Do this after adding the headers as it uses data from the headers
        let signingData = SigningData(url: url, method: method, headers: headers, body: body, bodyHash: bodyHash, timestamp: timestamp, date: dateString, signer: self, minimal: mode == .minimal)

        // construct authorization string as in https://www.tencentcloud.com/document/api/213/33224#4.-concatenating-the-authorization
        let authorization = "TC3-HMAC-SHA256 " +
            "Credential=\(credential.secretId)/\(dateString)/\(service)/tc3_request, " +
            "SignedHeaders=\(signingData.signedHeaders), " +
            "Signature=\(signature(signingData: signingData))"

        // add Authorization header
        headers.replaceOrAdd(name: "authorization", value: authorization)

        // now we have signed the request we can add the security token if required
        if omitSessionToken, let sessionToken = credential.token {
            headers.replaceOrAdd(name: "x-tc-token", value: sessionToken)
        }

        return headers
    }
}

extension TCSignerV3 {
    /// structure used to store data used throughout the signing process
    struct SigningData {
        let path: String
        let query: String
        let method: HTTPMethod
        let hashedPayload: String
        let timestamp: String
        let date: String
        let headers: HTTPHeaders
        let signedHeaders: String

        init(url: URLComponents, method: HTTPMethod, headers: HTTPHeaders = HTTPHeaders(), body: BodyData? = nil, bodyHash: String? = nil, timestamp: String, date: String, signer: TCSignerV3, minimal: Bool = false) {
            self.path = url.path.isEmpty ? "/" : url.path
            self.query = url.percentEncodedQuery ?? ""
            self.method = method
            self.timestamp = timestamp
            self.date = date

            if let hash = bodyHash {
                self.hashedPayload = hash
            } else {
                self.hashedPayload = TCSignerV3.hashedPayload(body)
            }

            self.headers = TCSignerV3.headersToSign(headers, minimal: minimal)
            self.signedHeaders = self.headers.map(\.name).joined(separator: ";")
        }
    }

    /// Stage 3 Calculating signature as in https://www.tencentcloud.com/document/api/213/33224#3.-calculating-the-signature
    func signature(signingData: SigningData) -> String {
        let signingSecret = self.signingSecret(date: signingData.date)
        let signature = HMAC<SHA256>.authenticationCode(for: [UInt8](stringToSign(signingData: signingData).utf8), using: signingSecret)
        return signature.hexDigest()
    }

    /// Stage 2 Create the string to sign as in https://www.tencentcloud.com/document/api/213/33224#2.-concatenating-the-string-to-be-signed
    func stringToSign(signingData: SigningData) -> String {
        let stringToSign = "TC3-HMAC-SHA256\n" +
            "\(signingData.timestamp)\n" +
            "\(signingData.date)/\(service)/tc3_request\n" +
            SHA256.hash(data: [UInt8](canonicalRequest(signingData: signingData).utf8)).hexDigest()
        return stringToSign
    }

    /// Stage 1 Create the canonical request as in https://www.tencentcloud.com/document/api/213/33224#1.-concatenating-the-canonicalrequest-string
    func canonicalRequest(signingData: SigningData) -> String {
        let canonicalHeaders = signingData.headers
            .map { "\($0.name):\($0.value)\n" }
            .joined()
        let canonicalRequest = "\(signingData.method.rawValue)\n" +
            "\(signingData.path)\n" +
            "\(signingData.query)\n" +
            "\(canonicalHeaders)\n" +
            "\(signingData.signedHeaders)\n" +
            signingData.hashedPayload
        return canonicalRequest
    }

    /// Compute signing key.
    func signingSecret(date: String) -> SymmetricKey {
        let secretDate = HMAC<SHA256>.authenticationCode(for: [UInt8](date.utf8), using: SymmetricKey(data: [UInt8]("TC3\(credential.secretKey)".utf8)))
        let secretService = HMAC<SHA256>.authenticationCode(for: [UInt8](service.utf8), using: SymmetricKey(data: secretDate))
        let signingSecret = HMAC<SHA256>.authenticationCode(for: [UInt8]("tc3_request".utf8), using: SymmetricKey(data: secretService))
        return SymmetricKey(data: signingSecret)
    }

    /// Create a SHA256 hash of the Requests body.
    static func hashedPayload(_ payload: BodyData?) -> String {
        guard let payload = payload else { return hashedEmptyBody }
        let hash: String?
        switch payload {
        case .string(let string):
            hash = SHA256.hash(data: [UInt8](string.utf8)).hexDigest()
        case .data(let data):
            hash = SHA256.hash(data: data).hexDigest()
        case .byteBuffer(let byteBuffer):
            let byteBufferView = byteBuffer.readableBytesView
            hash = byteBufferView.withContiguousStorageIfAvailable { bytes in
                return SHA256.hash(data: bytes).hexDigest()
            }
        case .unsignedPayload:
            return "UNSIGNED-PAYLOAD"
        }
        if let hash = hash {
            return hash
        } else {
            return hashedEmptyBody
        }
    }
    
    /// return the string formatted for signing requests
    static func dateString(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// return a timestamp formatted for signing requests
    static func timestamp(_ date: Date) -> String {
        String(UInt64(date.timeIntervalSince1970))
    }

    /// return the headers for signing requests
    static func headersToSign(_ headers: HTTPHeaders, minimal: Bool) -> HTTPHeaders {
        var headersToSign: HTTPHeaders = [:]

        if minimal {
            for header in ["content-type", "host"] {
                if let value = headers.first(name: header) {
                    headersToSign.add(name: header, value: value)
                }
            }
        } else {
            headersToSign = headers
            for header in ["authorization", "content-length", "expect", "user-agent"] {
                headersToSign.remove(name: header)
            }
        }

        return HTTPHeaders(
            headersToSign.map {
                ($0.name.lowercased(), $0.value.trimmingCharacters(in: .whitespaces).lowercased())
            }.sorted { $0.0 < $1.0 }
        )
    }

    /// returns port from URL. If port is set to 80 on an http url or 443 on an https url nil is returned
    private static func port(from url: URLComponents) -> Int? {
        guard let port = url.port else { return nil }
        guard url.scheme != "http" || port != 80 else { return nil }
        guard url.scheme != "https" || port != 443 else { return nil }
        return port
    }

    private static func hostname(from url: URLComponents) -> String {
        "\(url.host ?? "")\(port(from: url).map { ":\($0)" } ?? "")"
    }
}

private extension Sequence where Element == UInt8 {
    /// return a hex-encoded string buffer from an array of bytes
    func hexDigest() -> String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}
