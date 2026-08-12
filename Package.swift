// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBaseProject",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "STBaseProject",
            targets: ["STBaseProject"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "STBaseProject",
            dependencies: [
            ],
            path: "Sources",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
