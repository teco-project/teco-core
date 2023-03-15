# Signing API requests

Generate properly-signed HTTP headers for your Tencent Cloud API request.

## Overview

Tencent Cloud API authenticates every single request, i.e., the request must be signed using the security credentials in the designated steps. Each request has to contain the signature information and be sent in the specified way and format.

``TCSigner`` makes it easy to sign an API request using the `TC3-HMAC-SHA256` signature algorithm, which is recommended for higher security and better performance.

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
let signer = TCSigner(credential: credential, service: "cvm")
```

## Prepare a request for signing

Before performing the signing step, you need to extract necessary information from a request.

Pre-process the request URL using ``TCSigner/processURL(url:)``, so that it meets the requirement of Tencent Cloud API service. This function will return `nil` if the supplied URL is invalid.

```swift
guard let rawURL = URL(string: "https://cvm.tencentcloudapi.com/"),
      let url = signer.processURL(url: rawURL)
else {
    return nil
}
```

Wrap the request body into ``TCSigner/BodyData``. The following sample uses an empty JSON body.

```swift
let body: TCSigner.BodyData = .string("{}")
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

You can generate signed headers using ``TCSigner/signHeaders(url:method:headers:body:mode:omitSessionToken:date:)``. The following sample shows a simple signing step with request URL, headers and body.

```swift
let signedHeaders = signer.signHeaders(
    url: url,
    headers: headers,
    body: body
)
```

By default, the signer assumes the request to use current time and `POST` method. You can override the behavior based on your use case. The following sample signs a `GET` request for 10 seconds ago.

```swift
let signedHeadersForGETRequest = signer.signHeaders(
    url: URL(string: "https://cvm.tencentcloudapi.com/?Limit=10&Offset=10")!,
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

There are some other configurations to control signing behavior. For example, `omitSessionToken` specifies whether ``Credential/token`` is used for signature.

```swift
let signedHeadersOmittingToken = signer.signHeaders(
    url: url,
    headers: headers,
    body: body,
    omitSessionToken: true
)
```

``TCSigner/SigningMode`` controls how the signer signs a request. By default, the signer takes all statically available headers for maximal security. The following sample uses minimal signing mode, which is slightly faster while being less secure.

```swift
let signedHeadersUsingMinimalMode = signer.signHeaders(
    url: url,
    headers: headers,
    body: body,
    mode: .minimal
)
```
