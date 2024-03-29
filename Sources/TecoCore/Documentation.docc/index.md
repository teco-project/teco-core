#  ``TecoCore``

@Metadata {
    @DisplayName("Teco Core")
}

The core library of Teco, an open-source Tencent Cloud SDK for Swift.

## Overview

The Teco project, heavily inspired by [Soto](https://github.com/soto-project), aims to provide a fully-functional and powerful Tencent Cloud SDK that allows Swift developers to use Tencent Cloud APIs easily within their server or client applications.

This library provides most common functionalities around calling Tencent Cloud APIs.

## Topics

### Client

- ``TCClient``
- ``TCPayload``

### Services

- ``TCService``
- ``TCServiceConfig``

- ``TCRegion``

### Models

- ``TCModel``

- ``TCInputModel``
- ``TCOutputModel``

- ``TCRequest``
- ``TCMultipartRequest``
- ``TCPaginatedRequest``

- ``TCResponse``
- ``TCPaginatedResponse``

- ``TCRequestModel``
- ``TCResponseModel``

### Credentials

- ``CredentialProvider``
- ``CredentialProviderFactory``
- ``CredentialProviderError``

- ``ExpiringCredential``

- ``TemporaryCredential``
- ``TecoSigner/StaticCredential``

- ``DeferredCredentialProvider``
- ``TemporaryCredentialProvider``
- ``NullCredentialProvider``

### Retry

- ``RetryPolicy``
- ``RetryPolicyFactory``

- ``RetryStatus``

### Endpoint

- ``EndpointProvider``
- ``EndpointProviderFactory``

### Error Handling

- ``TCClient/ClientError``
- ``TCClient/PaginationError``

- ``TCErrorContext``

- ``TCErrorType``
- ``TCServiceErrorType``

- ``TCRawError``
- ``TCRawServiceError``

- ``TCCommonError``
