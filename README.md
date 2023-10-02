# Teco Core

The core library of [Teco](https://github.com/teco-project/teco), an open-source Tencent Cloud SDK for Swift.

## Overview

The Teco project, heavily inspired by [Soto](https://github.com/soto-project), aims to provide a fully-functional and powerful Tencent Cloud SDK that allows Swift developers to use Tencent Cloud APIs easily within their server or client applications.

This package provides common functionalities around calling Tencent Cloud APIs, in the following products:

- `TecoCore`. This provides helpers for calling Tencent Cloud API v3.
- `TecoSigner`. This provides helpers for using Tencent Cloud v1, v3 and COS signing algorithms.

## Usage

Add the following entry in your `Package.swift`:

```swift
.package(url: "https://github.com/teco-project/teco-core.git", "0.5.0"..<"0.6.0"),
```

and `TecoCore` dependency to your target:

```swift
.target(name: "MyApp", dependencies: [.product(name: "TecoCore", package: "teco-core")]),
```

If you only want signing functionality, use `TecoSigner` instead:

```swift
.target(name: "MyApp", dependencies: [.product(name: "TecoSigner", package: "teco-core")]),
```

## License

Teco Core is released under the Apache 2.0 license. See [LICENSE.txt](LICENSE.txt) for details.
