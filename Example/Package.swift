//
//  Package.swift
//  STBaseProject
//
//  Created by song on 2022/12/27.
//  Copyright © 2024 STBaseProject. All rights reserved.
//


let package = Package(
    name: "STBaseProject",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "JFPopup",
            targets: ["JFPopup"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/JerryFans/JRBaseKit.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "JFPopup",
            dependencies: [
                .product(name: "JRBaseKit", package: "JRBaseKit")
            ],
            resources: [.process("Resources")]
        )
    ]
)
