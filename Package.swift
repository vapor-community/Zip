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
            path: "Zip/minizip",
            exclude: ["module"],
            linkerSettings: [
                .linkedLibrary("z")
            ]
        ),
        .target(
            name: "Zip",
            dependencies: [
                .target(name: "Minizip"),
            ],
            path: "Zip",
            exclude: ["minizip", "zlib"]
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
