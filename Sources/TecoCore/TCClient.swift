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

#if compiler(>=5.6)
@preconcurrency import Atomics
#else
import Atomics
#endif
import AsyncHTTPClient
import Dispatch
import struct Foundation.URL
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOHTTP1
import TecoSigner

/// Client managing communication with Tencent Cloud services.
///
/// This is the workhorse of TecoCore. You provide it with a ``TCEncodableData`` Input object, it converts it to ``TCRequest`` which is then converted
/// to a raw `HTTPClient` Request. This is then sent to Tencent Cloud. When the response from Tencent Cloud is received if it is successful it is converted
/// to a ``TCResponse``, which is then decoded to generate a ``TCDecodableData`` Output object. If it is not successful then `TCClient` will throw
/// an ``TCErrorType``.
public final class TCClient {
    // MARK: Member variables
    
    /// Default logger that logs nothing
    public static let loggingDisabled = Logger(label: "Teco-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })
    
    static let globalRequestID = ManagedAtomic<Int>(0)
    
    /// Tencent Cloud credential provider
    public let credentialProvider: CredentialProvider
    /// HTTP client used by TCClient
    public let httpClient: HTTPClient
    /// Keeps a record of how we obtained the HTTP client
    let httpClientProvider: HTTPClientProvider
    /// EventLoopGroup used by TCClient
    public var eventLoopGroup: EventLoopGroup { return httpClient.eventLoopGroup }
    /// Logger used for non-request based output
    let clientLogger: Logger
    /// client options
    let options: Options
    
    internal let isShutdown = ManagedAtomic<Bool>(false)
    
    // MARK: Initialization
    
    /// Initialize an TCClient struct
    /// - parameters:
    ///     - credentialProvider: An object that returns valid signing credentials for request signing.
    ///     - options: Configuration flags
    ///     - httpClientProvider: HTTPClient to use. Use `.createNew` if you want the client to manage its own HTTPClient.
    ///     - logger: Logger used to log background TCClient events
    public init(
        credentialProvider credentialProviderFactory: CredentialProviderFactory = .default,
        options: Options = Options(),
        httpClientProvider: HTTPClientProvider,
        logger clientLogger: Logger = TCClient.loggingDisabled
    ) {
        // setup httpClient
        self.httpClientProvider = httpClientProvider
        switch httpClientProvider {
        case .shared(let providedHTTPClient):
            self.httpClient = providedHTTPClient
        case .createNewWithEventLoopGroup(let elg):
            self.httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .shared(elg), configuration: .init(timeout: .init(connect: .seconds(10))))
        case .createNew:
            self.httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .createNew, configuration: .init(timeout: .init(connect: .seconds(10))))
        }
        
        self.credentialProvider = credentialProviderFactory.createProvider(context: .init(
            httpClient: httpClient,
            eventLoop: httpClient.eventLoopGroup.next(),
            logger: clientLogger,
            options: options
        ))
        
        self.clientLogger = clientLogger
        self.options = options
    }
    
    deinit {
        assert(self.isShutdown.load(ordering: .relaxed), "TCClient not shut down before the deinit. Please call client.syncShutdown() when no longer needed.")
    }
    
    // MARK: Shutdown
    
    /// Shutdown client synchronously.
    ///
    /// Before an `TCClient` is deleted you need to call this function or the async version `shutdown`
    /// to do a clean shutdown of the client. It cleans up `CredentialProvider` tasks and shuts down the HTTP client if it was created by
    /// the `TCClient`.
    ///
    /// - Throws: TCClient.ClientError.alreadyShutdown: You have already shutdown the client
    public func syncShutdown() throws {
        let errorStorageLock = NIOLock()
        var errorStorage: Error?
        let continuation = DispatchWorkItem {}
        self.shutdown(queue: DispatchQueue(label: "tc-client.shutdown")) { error in
            if let error = error {
                errorStorageLock.withLock {
                    errorStorage = error
                }
            }
            continuation.perform()
        }
        continuation.wait()
        try errorStorageLock.withLock {
            if let error = errorStorage {
                throw error
            }
        }
    }
    
    /// Shutdown TCClient asynchronously.
    ///
    /// Before an `TCClient` is deleted you need to call this function or the synchronous
    /// version `syncShutdown` to do a clean shutdown of the client. It cleans up `CredentialProvider` tasks and shuts down
    /// the HTTP client if it was created by the `TCClient`. Given we could be destroying the `EventLoopGroup` the client
    /// uses, we have to use a `DispatchQueue` to run some of this work on.
    ///
    /// - Parameters:
    ///   - queue: Dispatch Queue to run shutdown on
    ///   - callback: Callback called when shutdown is complete. If there was an error it will return with Error in callback
    public func shutdown(queue: DispatchQueue = .global(), _ callback: @escaping (Error?) -> Void) {
        guard self.isShutdown.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged else {
            callback(ClientError.alreadyShutdown)
            return
        }
        let eventLoop = eventLoopGroup.next()
        // ignore errors from credential provider. Don't need shutdown erroring because no providers were available
        credentialProvider.shutdown(on: eventLoop).whenComplete { _ in
            // if httpClient was created by TCClient then it is required to shutdown the httpClient.
            switch self.httpClientProvider {
            case .createNew, .createNewWithEventLoopGroup:
                self.httpClient.shutdown(queue: queue) { error in
                    if let error = error {
                        self.clientLogger.log(level: self.options.errorLogLevel, "Error shutting down HTTP client", metadata: [
                            "tc-error": "\(error)",
                        ])
                    }
                    callback(error)
                }
                
            case .shared:
                callback(nil)
            }
        }
    }
    
    // MARK: Member structs/enums
    
    /// Errors returned by `TCClient` code
    public enum ClientError: Error, Equatable {
        /// client has already been shutdown
        case alreadyShutdown
        /// URL provided to client is invalid
        case invalidURL
        /// Too much data has been supplied for the Request
        case tooMuchData
        /// Not enough data has been supplied for the Request
        case notEnoughData
        /// Waiter failed, but without an error. ie a successful api call was an error
        case waiterFailed
        /// Waiter failed to complete in time alloted
        case waiterTimeout
    }

    /// Specifies how `HTTPClient` will be created and establishes lifecycle ownership.
    public enum HTTPClientProvider {
        /// Use HTTPClient provided by the user. User is responsible for the lifecycle of the HTTPClient.
        case shared(HTTPClient)
        /// HTTPClient will be created by TCClient using provided EventLoopGroup. When `shutdown` is called, created `HTTPClient`
        /// will be shut down as well.
        case createNewWithEventLoopGroup(EventLoopGroup)
        /// `HTTPClient` will be created by `TCClient`. When `shutdown` is called, created `HTTPClient` will be shut down as well.
        case createNew
    }
    
    /// Additional options
    public struct Options {
        /// log level used for request logging
        let requestLogLevel: Logger.Level
        /// log level used for error logging
        let errorLogLevel: Logger.Level
        
        /// Initialize TCClient.Options
        /// - Parameter requestLogLevel:Log level used for request logging
        public init(
            requestLogLevel: Logger.Level = .debug,
            errorLogLevel: Logger.Level = .debug
        ) {
            self.requestLogLevel = requestLogLevel
            self.errorLogLevel = errorLogLevel
        }
    }
}


// MARK: Credential & Signature

extension TCClient {

    /// Get credential used by client
    /// - Parameters:
    ///   - eventLoop: optional eventLoop to run operation on
    ///   - logger: optional logger to use
    /// - Returns: Credential
    public func getCredential(on eventLoop: EventLoop? = nil, logger: Logger = TCClient.loggingDisabled) -> EventLoopFuture<Credential> {
        let eventLoop = eventLoop ?? self.eventLoopGroup.next()
        return self.credentialProvider.getCredential(on: eventLoop, logger: logger)
    }

    /// Generate signed headers
    /// - parameters:
    ///     - url : URL to sign
    ///     - httpMethod: HTTP method to use (.GET, .PUT, .PUSH etc)
    ///     - httpHeaders: Headers that are to be used with this URL.
    ///     - body: Payload to sign as well. While it is unnecessary to provide the body for S3 other services may require it
    ///     - serviceConfig: additional AWS service configuration used to sign the url
    ///     - logger: Logger to output to
    /// - returns:
    ///     A set of signed headers that include the original headers supplied
    public func signHeaders(
        url: URL,
        httpMethod: HTTPMethod,
        headers: HTTPHeaders = HTTPHeaders(),
        body: TCPayload,
        serviceConfig: TCServiceConfig,
        logger: Logger = TCClient.loggingDisabled
    ) -> EventLoopFuture<HTTPHeaders> {
        let logger = logger.attachingRequestId(
            Self.globalRequestID.wrappingIncrementThenLoad(ordering: .relaxed),
            action: "SignHeaders",
            service: serviceConfig.service
        )
        return createSigner(serviceConfig: serviceConfig, logger: logger).flatMapThrowing { signer in
            guard let cleanURL = signer.processURL(url: url) else {
                throw TCClient.ClientError.invalidURL
            }
            let body: TCSigner.BodyData? = body.asByteBuffer().map { .byteBuffer($0) }
            return signer.signHeaders(url: cleanURL, method: httpMethod, headers: headers, body: body)
        }
    }

    func createSigner(serviceConfig: TCServiceConfig, logger: Logger) -> EventLoopFuture<TCSigner> {
        return credentialProvider.getCredential(on: eventLoopGroup.next(), logger: logger).map { credential in
            return TCSigner(credential: credential, service: serviceConfig.service)
        }
    }
}

extension TCClient.ClientError: CustomStringConvertible {
    /// return human readable description of error
    public var description: String {
        switch self {
        case .alreadyShutdown:
            return "The TCClient is already shutdown"
        case .invalidURL:
            return """
            The request url is invalid format.
            This error is internal. So please make a issue on https://github.com/teco-project/teco/issues to solve it.
            """
        case .tooMuchData:
            return "You have supplied too much data for the Request."
        case .notEnoughData:
            return "You have not supplied enough data for the Request."
        case .waiterFailed:
            return "Waiter failed"
        case .waiterTimeout:
            return "Waiter failed to complete in time allocated"
        }
    }
}

extension Logger {
    func attachingRequestId(_ id: Int, action: String, service: String) -> Logger {
        var logger = self
        logger[metadataKey: "tc-service"] = .string(service)
        logger[metadataKey: "tc-action"] = .string(action)
        logger[metadataKey: "tc-request-id"] = "\(id)"
        return logger
    }
}


#if compiler(>=5.6)
extension TCClient: Sendable {}
extension TCClient.HTTPClientProvider: Sendable {}
extension TCClient.Options: Sendable {}
#endif
