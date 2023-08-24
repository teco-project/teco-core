# Signing API requests (V3)

Generate properly-signed HTTP headers for your Tencent Cloud API request using signature V3 (`TC3-HMAC-SHA256`).

## Overview

Tencent Cloud API authenticates every single request, i.e., the request must be signed using the security credentials in the designated steps. Each request has to contain the signature information and be sent in the specified way and format.

``TCSignerV3`` makes it easy to sign an API request using the `TC3-HMAC-SHA256` signature algorithm, which is recommended for higher security and better performance.

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

Then create a signer to sign requests for a service.

```swift
let signer = TCSignerV3(credential: credential, service: "cvm")
```

## Prepare a request for signing

Before performing the signing step, you need to extract necessary information from a request.

Make sure the request URL is compatible with [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986), which requires specific characters to be percent-encoded. The following sample shows a simple `POST` request endpoint.

```swift
let url = URL(string: "https://cvm.tencentcloudapi.com/")!
```

Wrap the request body into ``TCSignerV3/BodyData``. The following sample uses an empty JSON body.

```swift
let body: TCSignerV3.BodyData = .string("{}")
```

Supply required HTTP headers, which must include `Content-Type`. Common parameters often use keys in the form of `X-TC-<Param>`. You may also add custom header fields depending on your use case. 

```swift
let headers: HTTPHeaders = [
    "content-type": "application/json",
    "x-tc-action": "DescribeInstances",
    "x-tc-version": "2017-03-12",
    "x-tc-region": "ap-guangzhou",
]
```

> Header fields supplied for signature should not be changed once the request is signed. If you want to modify a header before the request is sent, exclude it from signing step and append it later.

## Generate signed request headers

You can generate signed headers using ``TCSignerV3/signHeaders(url:method:headers:body:mode:omitSessionToken:date:)-b8bp``. The following sample shows a simple signing step with request URL, headers and body.

```swift
let signedHeaders = signer.signHeaders(url: url, headers: headers, body: body)
```

> Important: This function may crash if the supplied URL is not valid according to RFC 3986. In the future release, it will be correctly marked as `throws`.

By default, the signer assumes the request to use current time and `POST` method. You can override the behavior based on your use case. The following sample signs a `GET` request for 10 seconds ago.

```swift
let signedHeadersForGETRequest = try signer.signHeaders(
    url: "https://cvm.tencentcloudapi.com/?Limit=10&Offset=10",
    method: .GET,
    headers: [
        "content-type": "application/x-www-form-urlencoded",
        "x-tc-action": "DescribeInstances",
        "x-tc-version": "2017-03-12",
        "x-tc-region": "ap-guangzhou",
    ],
    date: Date(timeIntervalSinceNow: -10)
)
```

Note that the ``TCSignerV3/signHeaders(url:method:headers:body:mode:omitSessionToken:date:)-1rcp6`` variant accepts the request URL in string, and may throw if the input is not valid URL. There's also a non-throwing variant ``TCSignerV3/signHeaders(url:method:headers:body:mode:omitSessionToken:date:)-39hja`` that takes a `URLComponent` struct instead, which is compatible with RFC 3986.

## Configure signing options

There are some other configurations to control signing behavior. For example, `omitSessionToken` specifies whether ``Credential/token`` is used for signature.

```swift
let signedHeadersOmittingToken = signer.signHeaders(
    url: url,
    headers: headers,
    body: body,
    omitSessionToken: true
)
```

``TCSignerV3/SigningMode`` controls how the signer signs a request. By default, the signer takes all statically available headers for maximal security. The following sample uses minimal signing mode, which is slightly faster while being less secure.

```swift
let signedHeadersUsingMinimalMode = signer.signHeaders(
    url: url,
    headers: headers,
    body: body,
    mode: .minimal
)
```
