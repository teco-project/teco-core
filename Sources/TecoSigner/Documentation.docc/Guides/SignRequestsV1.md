# Signing API requests with `HmacSHA1` and `HmacSHA256` (Unrecommended)

Generate properly-signed URL query for your Tencent Cloud API request using signature V1.

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

### Prepare the request URL

Before performing the signing step, you need to have a request URL.

The URL should be compatible with [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986), which requires specific characters to be percent-encoded. The following sample shows a simple `GET` request URL.

```swift
let url = URL(string: "https://region.tencentcloudapi.com/?Action=DescribeProducts&Version=2022-06-27")!
```

> URL supplied for signature should not be changed once the request is signed.

### Generate signed query string

You can generate signed query string using ``TCSignerV1/signQueryString(url:method:algorithm:omitSessionToken:nonce:date:)-9ykb0``. The following sample shows a simple signing step using request URL.

```swift
let signedQuery = try signer.signQueryString(url: url)
```

> The signer will throw ``TCSignerError/invalidURL`` if the URL is malformed.

By default, the signer assumes the request to use current time and `GET` method, and adds a random `nonce` for the request. You can override the behavior based on your use case. The following sample signs a request for 10 seconds ago, with `nonce` set to `888`.

```swift
let signedQueryWithNonce = signer.signQueryString(
    host: "region.tencentcloudapi.com",
    queryItems: [
        .init(name: "Action", value: "DescribeRegions"),
        .init(name: "Product", value: "cvm"),
        .init(name: "Version", value: "2022-06-27"),
    ],
    nonce: 888,
    date: Date(timeIntervalSinceNow: -10)
)
```

Note that there are non-throwing variants ``TCSignerV1/signQueryString(host:path:queryItems:method:algorithm:omitSessionToken:nonce:date:)`` and ``TCSignerV1/signQueryString(host:path:query:method:algorithm:omitSessionToken:nonce:date:)`` which accepts the request host, path and query directly.

There are some other configurations to control signing behavior. For example, `omitSessionToken` specifies whether ``Credential/token`` is used for signature.

```swift
let signedQueryOmittingToken = try signer.signQueryString(url: url, omitSessionToken: true)
```

### Use the signed query

With a signed query string, you can now form the signed request URL. You can construct a new URL string using the same host and path that's used for signing.

```swift
guard let url = URL(string: "https://region.tencentcloudapi.com/?\(signedQuery)") else {
    fatalError("Invalid request!")
}
```

Instead of using a URL string, you can also start with a `URL` and update it safely using `URLComponents`.

```swift
guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
      case urlComponents.percentEncodedQuery = signedQuery,
      let signedURL = urlComponents.url
else {
    fatalError("Invalid request!")
}
```

## Sign a `POST` request

### Prepare the request URL and body

Before performing the signing step, you need to have a request URL. `POST` request URL usually comes with no query, as shown in the following example.

```swift
let url = URL(string: "https://region.tencentcloudapi.com")!
```

> URL supplied for signature should not be changed once the request is signed.

``TCSignerV1`` (and the `HmacSHA1` algorithm) only supports signing a `POST` request with `application/x-www-form-urlencoded` content type, which basically sends the URL query as `POST` body. The following sample shows a simple `POST` request body.

```swift
let query = "Action=DescribeProducts&Version=2022-06-27"
```

### Generate signed query string

You can generate signed query string using ``TCSignerV1/signQueryString(url:query:method:algorithm:omitSessionToken:nonce:date:)-576vr``. The following sample shows a simple signing step using request URL and body.

```swift
let signedQuery = try signer.signQueryString(url: url, query: query)
```

> The signer will throw ``TCSignerError/invalidURL`` if the URL is malformed.

If a `query` parameter is provided along with `url`, the signer assumes the request to use `POST` method by default. It'll also use current time and add a random `nonce` for the request. You can override the behavior based on your use case. The following sample signs a request for 10 seconds ago, with `nonce` set to `888`.

```swift
let signedQueryWithNonce = try signer.signQueryString(
    url: "https://region.tencentcloudapi.com/",
    queryItems: [
        .init(name: "Action", value: "DescribeRegions"),
        .init(name: "Product", value: "cvm"),
        .init(name: "Version", value: "2022-06-27"),
    ],
    nonce: 888,
    date: Date(timeIntervalSinceNow: -10)
)
```

Note that the non-throwing variants ``TCSignerV1/signQueryString(host:path:queryItems:method:algorithm:omitSessionToken:nonce:date:)`` and ``TCSignerV1/signQueryString(host:path:query:method:algorithm:omitSessionToken:nonce:date:)`` are still available, but you'll have to specify the `method` parameter for a `POST` request.

```swift
let signedHandcraftQuery = signer.signQueryString(
    host: "tag.tencentcloudapi.com",
    queryItems: [
        .init(name: "Action", value: "GetTagValues"),
        .init(name: "Version", value: "2018-08-13"),
        .init(name: "TagKeys.0", value: "平台"),
    ],
    method: .POST
)
```

There are some other configurations to control signing behavior. For example, `omitSessionToken` specifies whether ``Credential/token`` is used for signature.

```swift
let signedQueryOmittingToken = try signer.signQueryString(url: url, query: query, omitSessionToken: true)
```

You can now use the signed query string as the `POST` request body, and send it to the request URL.

## Use the `HmacSHA256` algorithm

SHA1 is now recognized as an insecure hash function, making `HmacSHA1` unsafe in some situations. `HmacSHA256` is a safer algorithm than `HmacSHA1`, and should be used where applicable.

``TCSignerV1`` has built-in support for the `HmacSHA256` signing algorithm. You can sign a request using `HmacSHA256` by specifying the `algorithm` parameter.

```swift
let signedQueryWithHmacSHA256 = try signer.signQueryString(url: url, algorithm: .hmacSHA256)
```
