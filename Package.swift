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
            name: "Permissionary",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "PermissionaryTests",
            dependencies: ["Permissionary"]
        ),
    ]
)
