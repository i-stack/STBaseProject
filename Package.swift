// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBaseProject",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // 完整产品 - 包含所有功能
        .library(
            name: "STBaseProject",
            targets: ["STBaseProject"]
        ),
        
        // 基础架构模块
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
    targets: [
        // 基础架构模块
        .target(
            name: "STBaseModule"
        ),
        
        // STKit 专业功能模块
        .target(
            name: "STKitLocation",
            dependencies: ["STBaseModule"]
        ),
        .target(
            name: "STKitScan",
            dependencies: ["STBaseModule"]
        ),
        .target(
            name: "STKitMedia",
            dependencies: ["STBaseModule"]
        ),
        .target(
            name: "STKitDialog",
            dependencies: ["STBaseModule"]
        ),
        
        // 完整产品 - 依赖所有模块
        .target(
            name: "STBaseProject",
            dependencies: [
                "STBaseModule",
                "STKitLocation",
                "STKitScan",
                "STKitMedia",
                "STKitDialog"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)