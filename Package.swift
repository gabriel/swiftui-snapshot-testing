// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUISnapshotTesting",
    platforms: [.iOS(.v16), .macOS(.v15)],
    products: [
        .library(
            name: "SwiftUISnapshotTesting",
            targets: ["SwiftUISnapshotTesting"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.4")
    ],
    targets: [
        .target(
            name: "SwiftUISnapshotTesting",
            dependencies: [
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Sources",
        ),
        .testTarget(
            name: "SwiftUISnapshotTestingTests",
            dependencies: [
                "SwiftUISnapshotTesting"
            ],
            path: "Tests",
            exclude: ["__Snapshots__"]
        )
    ]
)
