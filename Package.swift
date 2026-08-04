// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "DeviceHubMask",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "DeviceHubCore", targets: ["DeviceHubCore"]),
    ],
    targets: [
        .target(
            name: "DeviceHubCore",
            path: "DeviceHubMask/Core"
        ),
        .testTarget(
            name: "DeviceHubCoreTests",
            dependencies: ["DeviceHubCore"],
            path: "Tests/DeviceHubCoreTests"
        ),
    ]
)
