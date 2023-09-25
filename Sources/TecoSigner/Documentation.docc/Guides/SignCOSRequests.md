# Signing COS API requests

Generate properly-signed URL or headers for your Cloud Object Storage XML API request (V5).

## Overview

Tencent Cloud COS (Cloud Object Storage) supports basic and advanced ACL based on security credentials. Requests involving private resources must be signed using the security credentials in the designated steps.

``COSSignerV5`` makes it easy to sign a COS V5 API request, which is recommended for full functionalities and continuous support.

## Create a signer instance

To sign a COS API request, you need a valid security credential. Basically, this can be the static API access key obtained from the [CAM console](https://console.tencentcloud.com/cam/capi), in the form of paired secret ID and secret key.

```swift
let credential = StaticCredential(secretId: "YOUR_SECRET_ID", secretKey: "YOUR_SECRET_KEY")
```

> It's strongly unrecommended to supply the API key of an operational account directly due to high security risk. Use dedicated sub-accounts for COS and other stoarge services instead.
>
> To learn more about using sub-accounts, see [Creating and Authorizing Sub-account](https://www.tencentcloud.com/document/product/598/40985) and [Access Key](https://www.tencentcloud.com/document/product/598/32675).
>
> For other security advice, see [Security Best Practice](https://www.tencentcloud.com/document/product/598/10592).

Then create a signer to sign requests.

```swift
let signer = COSSignerV5(credential: credential)
```

## Prepare a request for signing

Before performing the signing step, you need to extract necessary information from a request.

Make sure the request URL is compatible with [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986), which requires specific characters to be percent-encoded. The following sample shows a simple object URL with key `/example.json`.

```swift
let url = URL(string: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/example.json")!
```

> Note: The signer will throw a ``TCSignerError/invalidURL`` error if the URL is malformed, according to RFC 3986.

Prepare HTTP headers according to the API you want to use. The following sample contains `Host` of the bucket endpoint and `Content-Type` associated with the object.

```swift
let headers: HTTPHeaders = [
    "host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
    "content-type": "application/json",
]
```

> Header fields supplied for signature should not be changed once the request is signed. If you want to modify a header before the request is sent, exclude it from signing step and append it later.

## Generate signed request headers

A COS request allows signature as either HTTP headers or URL query items. For an immediate request, you can generate signed headers using ``COSSignerV5/signHeaders(url:method:headers:tokenKey:date:duration:)-39e44``. The following sample shows a simple signing step with request URL and headers.

```swift
let signedHeaders = try signer.signHeaders(url: url, headers: headers)
```

By default, the signer assumes the request to use current time and `PUT` method, and is valid for 10 minutes. You can override the behavior based on your use case. The following sample signs a valid `GET` request that's expiring in 2 hours.

```swift
let signedHeadersForGETRequest = try signer.signHeaders(
    url: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/example.mp4",
    method: .GET,
    headers: [
        "host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
        "range": "bytes=0-",
    ],
    duration: 2 * 60 * 60
)
```

Note that the ``COSSignerV5/signHeaders(url:method:headers:tokenKey:date:duration:)-9ukxr`` variant accepts the request URL in string. There's also a non-throwing variant ``COSSignerV5/signRequest(method:headers:path:parameters:date:duration:)`` that takes the original path and parameters without percent encoding.

## Generate signed request URLs

In some situations you may want to sign a URL, with which a user can perform the action later and by themselves. You can generate pre-signed URLs using ``COSSignerV5/signURL(url:method:headers:tokenKey:date:duration:)-1amy8``. The following sample shows a simple signing step with request URL and headers.

```swift
let signedURL = try signer.signURL(url: url, headers: [
    "host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com"
])
```

By default, the signer assumes the request to use current time and `GET` method, and is valid for 10 minutes. You can override the behavior based on your use case. The following sample signs a valid `PUT` request that's only usable within 30 seconds.

```swift
let signedURLForPUTRequest = try signer.signURL(
    url: "https://examplebucket-1250000000.cos.ap-beijing.myqcloud.com/example.mp4",
    method: .PUT,
    headers: [
        "host": "examplebucket-1250000000.cos.ap-beijing.myqcloud.com",
        "content-type": "video/mp4",
    ],
    duration: 30
)
```

Note that the ``COSSignerV5/signURL(url:method:headers:tokenKey:date:duration:)-7jixa`` variant accepts the request URL in string. There's also a non-throwing variant ``COSSignerV5/signParameters(method:headers:path:parameters:tokenKey:date:duration:)`` that takes the original path and parameters without percent encoding, and returns a list of percent-encoded `URLQueryItem`s with signature included.

## Set up session token key for other services

A temporary Tencent Cloud credential, usually generated from a temporary role session, contains not only the secret ID and secret key but also a corresponding session token. COS V5 API requests require placing the session token side by side to the signature, either as an HTTP header or a URL query item.

``COSSignerV5`` has built-in support for session tokens for COS requests, so you can get this almost for free. If you're using ``COSSignerV5`` with other Tencent Cloud products, however, they might have a different key for session tokens. You can change this by specifying the `tokenKey` parameter.

```swift
let signedHeadersForCLS = try signer.signHeaders(
    url: "http://ap-guangzhou.cls.tencentyun.com/structuredlog?topic_id=xxxxxxxx-xxxx-xxxx-xxxx",
    method: .POST,
    headers: [
        "host": "ap-guangzhou.cls.tencentyun.com",
        "content-type: application/x-protobuf",
    ],
    tokenKey: "x-cls-token"
)
```

> Not all Tencent Cloud services support both signed headers and URLs. Please refer to the API documentation for detailed information.
