// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BKPaywallKit",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "BKPaywallKit",
            targets: ["BKPaywallKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "BKPaywallKit",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
            ]
        ),
    ]
)
