// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBaseProject",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
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
        ),
        .library(
            name: "STMarkdown",
            targets: ["STMarkdown"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", branch: "main")
    ],
    targets: [
        .target(
            name: "STBaseProject",
            dependencies: [],
            path: "Sources",
            exclude: [
                "STContacts",
                "STLocation",
                "STMedia",
                "STMarkdown"
            ]
        ),
        .target(
            name: "STContacts",
            dependencies: [],
            path: "Sources/STContacts"
        ),
        .target(
            name: "STLocation",
            dependencies: [],
            path: "Sources/STLocation"
        ),
        .target(
            name: "STMedia",
            dependencies: [],
            path: "Sources/STMedia"
        ),
        .target(
            name: "STMarkdown",
            dependencies: [
                "STBaseProject",
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftMath", package: "SwiftMath")
            ],
            path: "Sources/STMarkdown",
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
