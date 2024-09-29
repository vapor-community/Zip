// swift-tools-version:5.8
import PackageDescription
#if canImport(Darwin) || swift(<6.0)
import Foundation
#else
import FoundationEssentials
#endif

let package = Package(
    name: "Zip",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(name: "Zip", targets: ["Zip"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CMinizip",
            cSettings: [
                .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Zip",
            dependencies: [
                .target(name: "CMinizip")
            ],
            cSettings: [
                .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ZipTests",
            dependencies: [
                .target(name: "Zip"),
            ],
            resources: [
                .copy("Resources"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
] }

if let target = package.targets.filter({ $0.name == "CMinizip" }).first {
#if os(Windows)
    if ProcessInfo.processInfo.environment["ZIP_USE_DYNAMIC_ZLIB"] == nil {
        target.cSettings?.append(contentsOf: [.define("ZLIB_STATIC")])
        target.linkerSettings = [.linkedLibrary("zlibstatic")]
    } else {
        target.linkerSettings = [.linkedLibrary("zlib")]
    }
#else
    target.linkerSettings = [.linkedLibrary("z")]
#endif
}
