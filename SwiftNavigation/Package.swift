// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftNavigation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SwiftNavigation",
            targets: ["SwiftNavigation"]
        )
    ],
    targets: [
        .target(
            name: "SwiftNavigation"
        ),
        .testTarget(
            name: "SwiftNavigationTests",
            dependencies: ["SwiftNavigation"]
        )
    ]
)
