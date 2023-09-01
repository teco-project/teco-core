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
