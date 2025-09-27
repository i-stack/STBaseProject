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
            name: "STBase",
            targets: ["STBase"]
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
            name: "STBaseProject",
            targets: ["STBase", "STContacts", "STLocation", "STMedia"]
        ),
    ],
    targets: [
        .target(
            name: "STBase",
            dependencies: [],
            path: "STBase/Sources"
        ),
        .target(
            name: "STContacts",
            dependencies: ["STBase"],
            path: "STContacts/Sources"
        ),
        .target(
            name: "STLocation",
            dependencies: ["STBase"],
            path: "STLocation/Sources"
        ),
        .target(
            name: "STMedia",
            dependencies: ["STBase"],
            path: "STMedia/Sources"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
