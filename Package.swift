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
        ),
        .library(
            name: "STContacts",
            targets: ["STContacts"]
        ),
        .library(
            name: "STLocation",
            targets: ["STLocation"]
        ),
        .library(
            name: "STMedia",
            targets: ["STMedia"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", branch: "main")
    ],
    targets: [
        .target(
            name: "STBaseProject",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftMath", package: "SwiftMath", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources",
            exclude: [
                "STContacts",
                "STLocation",
                "STMedia"
            ],
            resources: [
                .process("STMarkdown/Resources")
            ]
        ),
        .target(
            name: "STContacts",
            path: "Sources/STContacts"
        ),
        .target(
            name: "STLocation",
            path: "Sources/STLocation"
        ),
        .target(
            name: "STMedia",
            path: "Sources/STMedia"
        ),
        .testTarget(
            name: "STLocationTests",
            dependencies: ["STLocation"],
            path: "Tests/STLocationTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
