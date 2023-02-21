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

import TecoCore

/// Tencent Cloud API request model that represents a paginated query.
public protocol TCPaginatedRequest: TCRequestModel {
    /// Paginated response type for the request.
    associatedtype Response: TCPaginatedResponse

    /// Compute the next request based on API response.
    func getNextPaginatedRequest(with response: Response) -> Self?
}

/// Tencent Cloud API response model that contains a list of paginated result and a total count.
public protocol TCPaginatedResponse: TCResponseModel {
    /// The total count type to be extracted from the response.
    associatedtype Count: Sendable, Equatable
    /// The listed item type.
    associatedtype Item: Sendable

    /// Extract the total count from the paginated response.
    func getTotalCount() -> Count?
    /// Extract the returned item list from the paginated response.
    func getItems() -> [Item]
}

extension TCPaginatedResponse where Count == Never {
    /// Default implementation where the response doesn't contain a total count field.
    public func getTotalCount() -> Never? {
        return nil
    }
}