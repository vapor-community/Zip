// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "Zip",
    products: [
        .library(name: "Zip", targets: ["Zip"])
    ],
    targets: [
        .target(
            name: "Minizip",
            exclude: ["module"],
            swiftSettings: [
                .enableUpcomingFeature("ConciseMagicFile"),
            ],
            linkerSettings: [
                .linkedLibrary("z")
            ]
        ),
        .target(
            name: "Zip",
            dependencies: [
                .target(name: "Minizip"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ConciseMagicFile"),
            ]
        ),
        .testTarget(
            name: "ZipTests",
            dependencies: [
                .target(name: "Zip"),
            ],
            resources: [
                .copy("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ConciseMagicFile"),
            ]
        ),
    ]
)
