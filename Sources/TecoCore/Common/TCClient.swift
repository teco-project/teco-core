//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
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

#if compiler(>=5.6)
@preconcurrency import Atomics
#else
import Atomics
#endif
import AsyncHTTPClient
import Dispatch
import struct Foundation.URL
import Logging
import Metrics
import NIOConcurrencyHelpers
import NIOCore
import NIOHTTP1
import TecoSigner

/// Client managing communication with Tencent Cloud services.
///
/// This is the workhorse of TecoCore. You provide it with a ``TCRequestModel``, it converts it to `TCRequest` which is then converted to a raw `HTTPClient` request. This is then sent to Tencent Cloud.
///
/// When the response from Tencent Cloud is received, it will be converted to a `TCResponse`, which is then decoded to generate a ``TCResponseModel`` or to create and throw a ``TCErrorType``.
public final class TCClient: TecoSendable {
    // MARK: Member variables

    private static let globalRequestID = ManagedAtomic<Int>(0)

    /// Default logger that logs nothing.
    public static let loggingDisabled = Logger(label: "Teco-do-not-log", factory: { _ in SwiftLogNoOpLogHandler() })

    /// Tencent Cloud credential provider.
    public let credentialProvider: CredentialProvider
    /// HTTP client used by `TCClient`.
    public let httpClient: HTTPClient
    /// Keeps a record of how we obtained the HTTP client.
    private let httpClientProvider: HTTPClientProvider
    /// `EventLoopGroup` used by `TCClient`.
    public var eventLoopGroup: EventLoopGroup { return httpClient.eventLoopGroup }
    /// Retry policy specifying what to do when a request fails.
    public let retryPolicy: RetryPolicy
    /// Logger used for non-request based output.
    private let clientLogger: Logger
    /// Custom client options.
    private let options: Options
    /// Holds the client shutdown state.
    private let isShutdown = ManagedAtomic<Bool>(false)

    // MARK: Initialization

    /// Initialize an `TCClient`.
    ///
    /// - Parameters:
    ///    - credentialProvider: An object that returns valid signing credentials for request signing.
    ///    - retryPolicy: An object that tells what to do when a request fails.
    ///    - options: Client configurations.
    ///    - httpClientProvider: `HTTPClient` to use. Use `.createNew` if you want the client to manage its own `HTTPClient`.
    ///    - logger: Logger used to log background `TCClient` events.
    public init(
        credentialProvider credentialProviderFactory: CredentialProviderFactory = .default,
        retryPolicy retryPolicyFactory: RetryPolicyFactory = .default,
        options: Options = Options(),
        httpClientProvider: HTTPClientProvider,
        logger clientLogger: Logger = TCClient.loggingDisabled
    ) {
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

        self.retryPolicy = retryPolicyFactory.retryPolicy
        self.clientLogger = clientLogger
        self.options = options
    }
    
    deinit {
        assert(self.isShutdown.load(ordering: .relaxed), "TCClient not shut down before the deinit. Please call client.syncShutdown() when no longer needed.")
    }
    
    // MARK: Shutdown

    /// Shutdown client synchronously.
    ///
    /// Before an `TCClient` is deleted, you need to call this function or the async version ``shutdown(queue:_:)`` to do a clean shutdown of the client.
    /// It cleans up ``CredentialProvider`` tasks and shuts down the HTTP client if it was created by the `TCClient`.
    ///
    /// - Throws: `ClientError.alreadyShutdown`: You have already shutdown the client.
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

    /// Shutdown `TCClient` asynchronously.
    ///
    /// Before an `TCClient` is deleted, you need to call this function or the synchronous version ``syncShutdown()`` to do a clean shutdown of the client.
    /// It cleans up ``CredentialProvider`` tasks and shuts down the HTTP client if it was created by the `TCClient`.
    ///
    /// Given we could be destroying the `EventLoopGroup` the client uses, we have to use a `DispatchQueue` to run some of this work on.
    ///
    /// - Parameters:
    ///   - queue: Dispatch queue to run on.
    ///   - callback: Callback called when shutdown is complete. If there was an error it will return with `Error` in callback.
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

    /// Errors returned by `TCClient` code.
    public enum ClientError: Error, Equatable {
        /// Client has already been shutdown.
        case alreadyShutdown
        /// URL provided to the client is invalid.
        case invalidURL
    }

    /// Specifies how `HTTPClient` will be created and establishes lifecycle ownership.
    public enum HTTPClientProvider: TecoSendable {
        /// Use `HTTPClient` provided by the user.
        ///
        /// The user should be responsible for the lifecycle of the `HTTPClient`.
        case shared(HTTPClient)
        /// `HTTPClient` will be created by `TCClient` using provided `EventLoopGroup`.
        ///
        /// When `shutdown` is called, created `HTTPClient` will be shut down as well.
        case createNewWithEventLoopGroup(EventLoopGroup)
        /// `HTTPClient` will be created by `TCClient`.
        ///
        /// When `shutdown` is called, created `HTTPClient` will be shut down as well.
        case createNew
    }

    /// Additional options.
    public struct Options: TecoSendable {
        /// Log level used for request logging.
        let requestLogLevel: Logger.Level
        /// Log level used for error logging
        let errorLogLevel: Logger.Level

        /// Initialize `TCClient.Options`.
        ///
        /// - Parameters:
        ///   - requestLogLevel: Log level used for request logging.
        ///   - errorLogLevel: Log level used for error logging.
        public init(
            requestLogLevel: Logger.Level = .debug,
            errorLogLevel: Logger.Level = .debug
        ) {
            self.requestLogLevel = requestLogLevel
            self.errorLogLevel = errorLogLevel
        }
    }
}

// MARK: Custom API calls

extension TCClient {
    /// Execute a request with an input object and return a future with the output object generated from the response.
    ///
    /// - Parameters:
    ///    - action: Name of the Tencent Cloud action.
    ///    - path: Path to append to endpoint URL.
    ///    - httpMethod: HTTP method to use (`POST` by default).
    ///    - serviceConfig: Tencent Cloud service configuration.
    ///    - skipAuthorization: If authorization should be set to `SKIP`.
    ///    - input: API request payload.
    ///    - logger: Logger to log request details to.
    ///    - eventLoop: `EventLoop` to run request on.
    ///
    /// - Returns: ``EventLoopFuture`` containing output object that completes when response is received.
    public func execute<Input: TCRequestModel, Output: TCResponseModel>(
        action: String,
        path: String = "/",
        httpMethod: HTTPMethod = .POST,
        serviceConfig: TCServiceConfig,
        skipAuthorization: Bool = false,
        input: Input,
        outputs outputType: Output.Type = Output.self,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<Output> {
        self.execute(
            action: action,
            createRequest: {
                try TCRequest(
                    action: action,
                    path: path,
                    httpMethod: httpMethod,
                    input: input,
                    configuration: serviceConfig
                )
            },
            skipAuthorization: skipAuthorization,
            executor: { request, eventLoop, logger in
                self.httpClient.execute(request: request, timeout: serviceConfig.timeout, on: eventLoop, logger: logger)
            },
            config: serviceConfig,
            outputType: outputType,
            logger: logger,
            on: eventLoop
        )
    }

    /// Execute a request with empty body and return a future with the output object generated from the response.
    ///
    /// - Parameters:
    ///    - action: Name of the Tencent Cloud action.
    ///    - path: Path to append to endpoint URL.
    ///    - httpMethod: HTTP method to use (`GET` by default).
    ///    - serviceConfig: Tencent Cloud service configuration.
    ///    - skipAuthorization: If authorization should be set to `SKIP`.
    ///    - logger: Logger to log request details to.
    ///    - eventLoop: `EventLoop` to run request on.
    ///
    /// - Returns: ``EventLoopFuture`` containing output object that completes when response is received.
    public func execute<Output: TCResponseModel>(
        action: String,
        path: String = "/",
        httpMethod: HTTPMethod = .GET,
        serviceConfig: TCServiceConfig,
        skipAuthorization: Bool = false,
        outputs outputType: Output.Type = Output.self,
        logger: Logger = TCClient.loggingDisabled,
        on eventLoop: EventLoop? = nil
    ) -> EventLoopFuture<Output> {
        self.execute(
            action: action,
            createRequest: {
                try TCRequest(
                    action: action,
                    path: path,
                    httpMethod: httpMethod,
                    configuration: serviceConfig
                )
            },
            skipAuthorization: skipAuthorization,
            executor: { request, eventLoop, logger in
                self.httpClient.execute(request: request, timeout: serviceConfig.timeout, on: eventLoop, logger: logger)
            },
            config: serviceConfig,
            outputType: outputType,
            logger: logger,
            on: eventLoop
        )
    }
}

// MARK: Credential & Signature

extension TCClient {
    /// Get a valid credential for signing.
    ///
    /// - Parameters:
    ///   - eventLoop: Optional `EventLoop` to run operation on.
    ///   - logger: Optional logger to use.
    public func getCredential(on eventLoop: EventLoop? = nil, logger: Logger = TCClient.loggingDisabled) -> EventLoopFuture<Credential> {
        let eventLoop = eventLoop ?? self.eventLoopGroup.next()
        return self.credentialProvider.getCredential(on: eventLoop, logger: logger)
    }

    /// Generate signed headers.
    ///
    /// - Parameters:
    ///    - url : URL to sign.
    ///    - httpMethod: HTTP method to use (`.GET` or `.POST`).
    ///    - httpHeaders: Headers that are to be sent with this URL.
    ///    - body: Payload to sign.
    ///    - serviceConfig: Additional Tencent Cloud service configuration used to sign the URL.
    ///    - logger: Logger to output to.
    ///
    /// - Returns: A set of signed headers that include the original headers supplied.
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

    private func createSigner(serviceConfig: TCServiceConfig, logger: Logger) -> EventLoopFuture<TCSigner> {
        return credentialProvider.getCredential(on: eventLoopGroup.next(), logger: logger).map { credential in
            TCSigner(credential: credential, service: serviceConfig.service)
        }
    }
}

// MARK: Response helpers

extension TCClient {
    /// Generate a ``TCResponse`` from the HTTP response and return the output data from it.
    ///
    /// This is only every called if the response has http status code 200 OK.
    private func validate<Output: TCResponseModel>(response: TCHTTPResponse, serviceConfig: TCServiceConfig, logger: Logger) throws -> Output {
        assert((200..<300).contains(response.status.code), "Shouldn't get here if unexpected error happens")
        let tcResponse = try TCResponse(from: response)
        return try tcResponse.generateOutputData(errorType: serviceConfig.errorType, logLevel: options.errorLogLevel, logger: logger)
    }

    /// Create a raw error from ``TCHTTPResponse``.
    ///
    /// This is only called if we received an unsuccessful http status code.
    private func createRawError(for response: TCHTTPResponse, serviceConfig: TCServiceConfig, logger: Logger) -> TCRawError {
        // returns "Unhandled error message" with rawBody attached
        var rawBodyString: String?
        if var body = response.body {
            rawBodyString = body.readString(length: body.readableBytes)
        }
        let context = TCErrorContext(
            message: "Unhandled Error",
            responseCode: response.status,
            headers: response.headers
        )
        return TCRawError(rawBody: rawBodyString, context: context)
    }
}

// MARK: Internal implemenation

extension TCClient {
    /// The core executor.
    private func execute<Output: TCResponseModel>(
        action: String,
        createRequest: @escaping () throws -> TCRequest,
        skipAuthorization: Bool,
        executor: @escaping (TCHTTPRequest, EventLoop, Logger) -> EventLoopFuture<TCHTTPResponse>,
        config: TCServiceConfig,
        outputType: Output.Type,
        logger: Logger,
        on eventLoop: EventLoop?
    ) -> EventLoopFuture<Output> {
        let eventLoop = eventLoop ?? eventLoopGroup.next()
        let logger = logger.attachingRequestId(
            Self.globalRequestID.wrappingIncrementThenLoad(ordering: .relaxed),
            action: action,
            service: config.service
        )
        // get credential
        let future: EventLoopFuture<Output> = createSigner(serviceConfig: config, logger: logger)
            .flatMapThrowing { signer -> TCHTTPRequest in
                // create request and sign with signer
                let tcRequest = try createRequest()
                return tcRequest.createHTTPRequest(signer: signer, serviceConfig: config, skipAuthorization: skipAuthorization)
            }.flatMap { request -> EventLoopFuture<Output> in
                self.invoke(
                    with: config,
                    eventLoop: eventLoop,
                    logger: logger,
                    request: { eventLoop in executor(request, eventLoop, logger) }
                )
            }
        return recordRequest(future, service: config.service, action: action, logger: logger)
    }

    /// The core invoker.
    private func invoke<Output: TCResponseModel>(
        with serviceConfig: TCServiceConfig,
        eventLoop: EventLoop,
        logger: Logger,
        request: @escaping (EventLoop) -> EventLoopFuture<TCHTTPResponse>
    ) -> EventLoopFuture<Output> {
        let promise = eventLoop.makePromise(of: Output.self)

        func execute(attempt: Int) {
            // execute HTTP request
            request(eventLoop)
                .flatMapThrowing { response throws -> Void in
                    // Tencent Cloud will return 200 even for API error, so treat any other response status as error
                    guard response.status == .ok else {
                        throw self.createRawError(for: response, serviceConfig: serviceConfig, logger: logger)
                    }
                    let output: Output = try self.validate(response: response, serviceConfig: serviceConfig, logger: logger)
                    promise.succeed(output)
                }
                .flatMapErrorThrowing { error -> Void in
                    // If we get a retry wait time for this error, then attempt to retry request
                    if case .retry(let retryTime) = self.retryPolicy.getRetryWaitTime(error: error, attempt: attempt) {
                        logger.trace("Retrying request", metadata: [
                            "tc-retry-time": "\(Double(retryTime.nanoseconds) / 1_000_000_000)",
                        ])
                        // schedule task for retrying the request
                        eventLoop.scheduleTask(in: retryTime) {
                            execute(attempt: attempt + 1)
                        }
                    } else {
                        promise.fail(error)
                    }
                }
                .whenComplete { _ in }
        }
        execute(attempt: 0)

        return promise.futureResult
    }
}

// MARK: Helpers & Integrations

extension TCClient.ClientError: CustomStringConvertible {
    /// Human readable description of ``TCClient/ClientError``.
    public var description: String {
        switch self {
        case .alreadyShutdown:
            return "The TCClient is already shutdown"
        case .invalidURL:
            return """
            The request URL has invalid format.
            If you're using Teco, please file an issue on https://github.com/teco-project/teco/issues to help solve it.
            """
        }
    }
}

extension Logger {
    func attachingRequestId(_ id: Int, action: String, service: String) -> Logger {
        var logger = self
        logger[metadataKey: "tc-service"] = .string(service)
        logger[metadataKey: "tc-action"] = .string(action)
        logger[metadataKey: "tc-client-request-id"] = "\(id)"
        return logger
    }
}

extension TCClient {
    /// Record the request in `Metrics` and `Logging`.
    func recordRequest<Output>(_ future: EventLoopFuture<Output>, service: String, action: String, logger: Logger) -> EventLoopFuture<Output> {
        let dimensions: [(String, String)] = [("tc-service", service), ("tc-action", action)]
        let startTime = DispatchTime.now().uptimeNanoseconds

        Counter(label: "tc_requests_total", dimensions: dimensions).increment()
        logger.log(level: self.options.requestLogLevel, "Tencent Cloud Request")

        return future.map { response in
            logger.trace("Tencent Cloud Response")
            Metrics.Timer(
                label: "tc_request_duration",
                dimensions: dimensions,
                preferredDisplayUnit: .seconds
            ).recordNanoseconds(DispatchTime.now().uptimeNanoseconds - startTime)
            return response
        }.flatMapErrorThrowing { error in
            Counter(label: "tc_request_errors", dimensions: dimensions).increment()
            // TCErrorTypes have already been logged
            if error as? TCErrorType == nil {
                // log error message
                logger.log(level: self.options.errorLogLevel, "TCClient error", metadata: [
                    "tc-error-message": "\(error)",
                ])
            }
            throw error
        }
    }
}
