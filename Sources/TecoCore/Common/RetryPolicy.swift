//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2023 the Teco project authors
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
// Copyright (c) 2020-2022 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AsyncHTTPClient
import func Foundation.exp2

/// Creates a ``RetryPolicy`` for ``TCClient`` to use.
public struct RetryPolicyFactory {
    public let retryPolicy: RetryPolicy

    /// The default ``RetryPolicy``.
    public static var `default`: RetryPolicyFactory { return .jitter() }

    /// Never ask for retry.
    public static var noRetry: RetryPolicyFactory { return .init(retryPolicy: NoRetry()) }

    /// Retry with an exponentially increasing wait time.
    public static func exponential(base: TimeAmount = .seconds(1), maxRetries: Int = 4) -> RetryPolicyFactory {
        return .init(retryPolicy: ExponentialRetry(base: base, maxRetries: maxRetries))
    }

    /// Exponential jitter retry.
    ///
    /// Instead of returning an exponentially increasing retry time it returns a jittered version.
    /// In a heavy load situation where a large number of clients all hit the servers at the same time, jitter helps to smooth out the server response.
    public static func jitter(base: TimeAmount = .seconds(1), maxRetries: Int = 4) -> RetryPolicyFactory {
        return .init(retryPolicy: JitterRetry(base: base, maxRetries: maxRetries))
    }
}

/// Whether to wait for another retry and the time amount to wait.
public enum RetryStatus {
    /// Retry after `wait` amount of time.
    case retry(wait: TimeAmount)
    /// Do not retry.
    case dontRetry
}

/// Protocol for retry strategy.
///
/// Operation may retry a few times after an HTTP error.
public protocol RetryPolicy: Sendable {
    /// Returns whether we should retry and how long we should wait before retrying.
    ///
    /// - Parameters:
    ///   - error: The error returned by HTTP client.
    ///   - attempt: Retry attempt count.
    func getRetryWaitTime(error: Error, attempt: Int) -> RetryStatus?
}

/// Never ask for retry.
private struct NoRetry: RetryPolicy {
    init() {}
    func getRetryWaitTime(error: Error, attempt: Int) -> RetryStatus? {
        return .dontRetry
    }
}

/// Protocol for standard retry response.
protocol StandardRetryPolicy: RetryPolicy {
    var maxRetries: Int { get }
    func calculateRetryWaitTime(attempt: Int) -> TimeAmount
}

extension StandardRetryPolicy {
    func getRetryWaitTime(error: Error, attempt: Int) -> RetryStatus? {
        guard attempt < maxRetries else { return .dontRetry }

        switch error {
        case let error as TCCommonError where error ~= .requestLimitExceeded:
            // too many requests
            return .retry(wait: calculateRetryWaitTime(attempt: attempt))
        case let error as TCErrorType:
            if let context = error.context {
                // if response has a "Retry-After" header then use that
                if let retryAfterString = context.headers["Retry-After"].first, let retryAfter = Int64(retryAfterString) {
                    return .retry(wait: .seconds(retryAfter))
                }
                // server error
                if error.errorCode == TCCommonError.internalError.errorCode {
                    return .retry(wait: calculateRetryWaitTime(attempt: attempt))
                }
            }
            return .dontRetry
        #if DEBUG
        case let httpClientError as HTTPClientError where httpClientError == .remoteConnectionClosed:
            return .retry(wait: calculateRetryWaitTime(attempt: attempt))
        #endif
        default:
            return .dontRetry
        }
    }
}

/// Retry with an exponentially increasing wait time.
struct ExponentialRetry: StandardRetryPolicy {
    let base: TimeAmount
    let maxRetries: Int

    init(base: TimeAmount = .seconds(1), maxRetries: Int = 4) {
        self.base = base
        self.maxRetries = maxRetries
    }

    func calculateRetryWaitTime(attempt: Int) -> TimeAmount {
        let exp = Int64(exp2(Double(attempt)))
        return .nanoseconds(self.base.nanoseconds * exp)
    }
}

/// Exponential jitter retry.
///
/// Instead of returning an exponentially increasing retry time it returns a jittered version.
/// In a heavy load situation where a large number of clients all hit the servers at the same time, jitter helps to smooth out the server response.
struct JitterRetry: StandardRetryPolicy {
    let base: TimeAmount
    let maxRetries: Int

    init(base: TimeAmount = .seconds(1), maxRetries: Int = 4) {
        self.base = base
        self.maxRetries = maxRetries
    }

    func calculateRetryWaitTime(attempt: Int) -> TimeAmount {
        let exp = Int64(exp2(Double(attempt)))
        return .nanoseconds(Int64.random(in: (self.base.nanoseconds * exp / 2)..<(self.base.nanoseconds * exp)))
    }
}
