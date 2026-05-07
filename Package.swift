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
        // 通过 revision 锁定，保证可复现构建。升级时同步更新 Package.resolved。
        .package(url: "https://github.com/swiftlang/swift-markdown.git", revision: "55d66d9a9e8d4fd3f48d111b0d437e82fe451903"),
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
        )
        // 单元测试位于 STBaseProjectExample/STBaseProjectExampleTests/，
        // 通过 Xcode 的 STBaseProjectExample workspace 运行；SPM 不直接暴露 testTarget。
    ],
    swiftLanguageVersions: [.v5]
)
