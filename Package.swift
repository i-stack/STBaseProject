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
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.8.0"),
        .package(url: "https://github.com/mgriebling/SwiftMath.git", revision: "48ff188ba118c37d024551238041113560ab09b9")
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
                .process("STMarkdown/Resources"),
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "STContacts",
            path: "Sources/STContacts",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "STLocation",
            path: "Sources/STLocation",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "STMedia",
            path: "Sources/STMedia",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
