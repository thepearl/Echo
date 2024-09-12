// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Echo",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Echo",
            targets: ["Echo"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Echo",
            dependencies: []
        ),
        .testTarget(
            name: "EchoTests",
            dependencies: ["Echo"]),
    ]
)
