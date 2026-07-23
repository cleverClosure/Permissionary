// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Permissionary",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Permissionary",
            targets: ["Permissionary"]
        )
    ],
    targets: [
        .target(
            name: "Permissionary"
        ),
        .testTarget(
            name: "PermissionaryTests",
            dependencies: ["Permissionary"]
        ),
    ]
)
