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
            targets: ["STBaseProject"]
        )
    ],
    targets: [
        .target(
            name: "STBaseProject",
            dependencies: [],
            path: "Sources",
            sources: [
                "STBaseProject",
                "STDialog",
                "STLocation",
                "STMedia",
                "STScan"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)