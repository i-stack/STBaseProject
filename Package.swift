// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBaseProject",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // 完整产品 - 包含所有模块
        .library(
            name: "STBaseProject",
            targets: [
                "STBaseModule",
                "STKitLocation",
                "STKitScan",
                "STKitMedia",
                "STKitDialog"
            ]
        ),
        
        // 基础架构模块（包含 Core、UI、Security、Config）
        .library(
            name: "STBaseModule",
            targets: ["STBaseModule"]
        ),
        
        // STKit 专业功能模块
        .library(
            name: "STKitLocation",
            targets: ["STKitLocation"]
        ),
        .library(
            name: "STKitScan",
            targets: ["STKitScan"]
        ),
        .library(
            name: "STKitMedia",
            targets: ["STKitMedia"]
        ),
        .library(
            name: "STKitDialog",
            targets: ["STKitDialog"]
        )
    ],
    dependencies: [
        // 目前没有外部依赖，但可以在这里添加
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
    ],
    targets: [
        // MARK: - 基础架构模块（包含 Core、UI、Security、Config）
        .target(
            name: "STBaseModule",
            dependencies: [],
            path: "Sources/STBaseModule",
            resources: []
        ),
        
        // MARK: - STKit 专业功能模块
        .target(
            name: "STKitLocation",
            dependencies: ["STBaseModule"],
            path: "Sources/STKit/Location",
            resources: []
        ),
        
        .target(
            name: "STKitScan",
            dependencies: ["STBaseModule"],
            path: "Sources/STKit/Scan",
            resources: []
        ),
        
        .target(
            name: "STKitMedia",
            dependencies: ["STBaseModule"],
            path: "Sources/STKit/Media",
            resources: []
        ),
        
        .target(
            name: "STKitDialog",
            dependencies: ["STBaseModule"],
            path: "Sources/STKit/STDialog",
            resources: []
        ),
        
        // MARK: - 测试目标
        .testTarget(
            name: "STBaseProjectTests",
            dependencies: [
                "STBaseModule",
                "STKitLocation",
                "STKitScan",
                "STKitMedia",
                "STKitDialog"
            ],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)