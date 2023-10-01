// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "teco-core",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
       .library(
           name: "TecoCore",
           targets: ["TecoCore", "TecoDateHelpers", "TecoPaginationHelpers"]),
       .library(
           name: "TecoSigner",
           targets: ["TecoSigner"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.4.1"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", "1.0.0"..<"3.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0"..<"4.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/multipart-kit.git", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TecoCore",
            dependencies: [
                .byName(name: "INIParser"),
                .byName(name: "TecoSigner"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "MultipartKit", package: "multipart-kit"),
            ]),
        .target(name: "TecoPaginationHelpers",
                dependencies: ["TecoCore"]),
        .target(name: "TecoDateHelpers"),
        .target(name: "INIParser"),
        .target(
            name: "TecoSigner",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]),
        .testTarget(
            name: "TecoSignerTests",
            dependencies: ["TecoSigner"]),
    ]
)
