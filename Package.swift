// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Zip",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v4),
    ],
    products: [
        .library(name: "Zip", targets: ["Zip"]),
    ],
    targets: [
        .target(name: "Minizip"),
        .target(
            name: "Zip",
            dependencies: [
                .target(name: "Minizip"),
            ]
        ),
        .testTarget(
            name: "ZipTests",
            dependencies: [
                .target(name: "Zip"),
            ],
            resources: [
                .copy("Resources"),
            ]
        ),
    ]
)
