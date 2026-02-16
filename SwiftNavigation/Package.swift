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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0")
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
