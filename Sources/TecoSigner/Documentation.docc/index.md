#  ``TecoSigner``

@Metadata {
    @DisplayName("Teco Signer")
}

Signing helpers for Tencent Cloud APIs.

## Overview

This library provides a set of utilities around signing [Tencent Cloud](https://www.tencentcloud.com) API requests using signature V3 (`TC3-HMAC-SHA256`) and V1 (`HmacSHA1`/`HmacSHA256`).

It also defines the interface of Tencent Cloud security credentials.

## Topics

### Signing (V3)

- <doc:SignRequestsV3>
- ``TCSignerV3``
- ``TCSigner``

### Signing (V1)

- <doc:SignRequestsV1>
- ``TCSignerV1``

### COS Signing

- <doc:SignCOSRequests>
- ``COSSignerV5``

### Credentials

- ``Credential``
- ``StaticCredential``

### Errors

- ``TCSignerError``
