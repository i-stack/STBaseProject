// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBaseProject",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "STBase",
            targets: ["STBase"]
        ),
        .library(
            name: "STLocation",
            targets: ["STLocation"]
        ),
        .library(
            name: "STContacts",
            targets: ["STContacts"]
        ),
        .library(
            name: "STMedia",
            targets: ["STMedia"]
        ),
    ],
    targets: [
        .target(
            name: "STBase",
            dependencies: [],
            path: "Sources/STBase"
        ),
        .target(
            name: "STLocation",
            dependencies: [],
            path: "Sources/STLocation"
        ),
        .target(
            name: "STContacts",
            dependencies: [],
            path: "Sources/STContacts"
        ),
        .target(
            name: "STMedia",
            dependencies: [],
            path: "Sources/STMedia"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
