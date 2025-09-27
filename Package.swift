// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBaseProject",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "STBaseProject",
            targets: ["STBase"]
        ),
    ],
    targets: [
        .target(
            name: "STBase",
            dependencies: [],
            path: "Sources/STBase"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
