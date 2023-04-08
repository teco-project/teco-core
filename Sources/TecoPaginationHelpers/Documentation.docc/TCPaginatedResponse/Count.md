# ``TecoPaginationHelpers/TCPaginatedResponse/Count``

## Discussion

Most paginated Tencent Cloud APIs return the total element count for the queried items in a `BinaryInteger`, eg. `UInt64`. We use this value to ensure the queried result didn't change during pagination, and will throw a ``TecoPaginationHelpers/TecoCore/TCClient/PaginationError/totalCountChanged`` error if it changed unexpectedly.

Some paginated API responses, however, doesn't have a total count field. For these response models, ``Count`` should be `Never` and ``getTotalCount()-9zl99`` will always return `nil`.
