# Signing API requests (V1, unrecommended)

Generate properly-signed URL or body for your Tencent Cloud API request using signature V1 (`HmacSHA1`/`HmacSHA256`).

## Overview

Tencent Cloud API authenticates every single request, i.e., the request must be signed using the security credentials in the designated steps. Each request has to contain the signature information and be sent in the specified way and format.

``TCSignerV1`` makes it easy to sign an API request using the `HmacSHA1` and `HmacSHA256` signature algorithm. It may be required for some legacy APIs, but for higher security you should use ``TCSignerV3`` as described in <doc:SignRequestsV3> in the first place.

## Create a signer instance

To sign an API request, you need a valid security credential. Basically, this can be the static API access key obtained from the [CAM console](https://console.tencentcloud.com/cam/capi), in the form of paired secret ID and secret key.

```swift
let credential = StaticCredential(secretId: "YOUR_SECRET_ID", secretKey: "YOUR_SECRET_KEY")
```

> It's strongly unrecommended to supply the API key of a root account directly due to high security risk.
>
> To learn more about using sub-accounts, see [Creating and Authorizing Sub-account](https://www.tencentcloud.com/document/product/598/40985) and [Access Key](https://www.tencentcloud.com/document/product/598/32675).
>
> For other security advice, see [Security Best Practice](https://www.tencentcloud.com/document/product/598/10592).

Then create a signer to sign requests.

```swift
let signer = TCSignerV1(credential: credential)
```

## Sign a `GET` request

Before performing the signing step, you need to have a request URL.

The URL should be compatible with [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986), which requires specific characters to be percent-encoded. The following sample shows a simple `GET` request URL.

```swift
let url = URL(string: "https://region.tencentcloudapi.com/?Action=DescribeProducts&Version=2022-06-27")!
```

You can generate a signed URL using ``TCSignerV1/signURL(url:algorithm:omitSessionToken:nonce:date:)-6gu5z`` for a `GET` request. The following sample shows a simple signing step.

```swift
let signedURL = try signer.signURL(url: url)
```

> Note: The signer will throw a ``TCSignerError/invalidURL`` error if the URL is malformed, according to RFC 3986.

## Sign a `POST` request

A `POST` request URL usually comes with no query, as shown in the following example.

```swift
let postURL = URL(string: "https://region.tencentcloudapi.com")!
```

> Important: URL supplied for signature should not be changed once the request is signed.

Signature V1 only supports signing a `POST` request with `application/x-www-form-urlencoded` content type, which basically encodes the URL query as `POST` body. ``TCSignerV1`` uses `URLQueryItem`s as the request input, so that you don't need to handle the encoding manually. The following sample shows a simple list of query items.

```swift
let queryItems: [URLQueryItem] = [
    .init(name: "Action", value: "DescribeRegions"),
    .init(name: "Product", value: "cvm"),
    .init(name: "Version", value: "2022-06-27"),
]
```

You can generate a signed request body using ``TCSignerV1/signBody(url:queryItems:algorithm:omitSessionToken:nonce:date:)-9hb3o``.  The following sample shows a simple signing step using request URL and query items.

```swift
let signedBody = try signer.signBody(url: postURL, queryItems: queryItems)
```

## Configure signing options

By default, the signer assumes the request to use current time, and adds a random `nonce` for the request. You can override the behavior based on your use case. The following sample signs a request for 10 seconds ago, with `nonce` set to `888`.

```swift
let signedBodyWithNonce = try signer.signBody(
    url: "https://tag.tencentcloudapi.com",
    queryItems: [
        .init(name: "Action", value: "GetTagValues"),
        .init(name: "Version", value: "2018-08-13"),
        .init(name: "TagKeys.0", value: "平台"),
    ],
    nonce: 888,
    date: Date(timeIntervalSinceNow: -10)
)
```

Note that there are ``TCSignerV1/signBody(url:queryItems:algorithm:omitSessionToken:nonce:date:)-knwl`` and ``TCSignerV1/signBody(url:queryItems:algorithm:omitSessionToken:nonce:date:)-knwl`` variants that accept the request URL in string. There's also a non-throwing variant ``TCSignerV1/signQueryItems(host:path:queryItems:method:algorithm:omitSessionToken:nonce:date:)`` that takes the host, path and query items directly and outputs a list of `URLQueryItem`s with signature included.

There are some other configurations to control signing behavior. For example, `omitSessionToken` specifies whether ``Credential/token`` is used for signature.

```swift
let signedURLOmittingToken = try signer.signURL(url: url, omitSessionToken: true)
```

## Use the `HmacSHA256` algorithm

SHA1 is now recognized as an insecure hash function, making `HmacSHA1` unsafe in some situations. `HmacSHA256` is a safer algorithm than `HmacSHA1`, and should be used where applicable.

``TCSignerV1`` has built-in support for the `HmacSHA256` signing algorithm. You can sign a request using `HmacSHA256` by specifying the `algorithm` parameter.

```swift
let signedURLWithHmacSHA256 = try signer.signURL(url: url, algorithm: .hmacSHA256)
```
