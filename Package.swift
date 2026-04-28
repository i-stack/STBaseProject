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
                .product(name: "SwiftMath", package: "SwiftMath")
            ],
            path: "Sources",
            resources: [
                .process("STMarkdown/Resources")
            ]
        ),
        .testTarget(
            name: "STBaseProjectTests",
            dependencies: ["STBaseProject"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
