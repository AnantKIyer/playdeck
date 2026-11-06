// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlaydeckProtocol",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "PlaydeckProtocol",
            targets: ["PlaydeckProtocol"]
        ),
    ],
    targets: [
        .target(
            name: "PlaydeckProtocol",
            path: "Sources/PlaydeckProtocol"
        ),
        .testTarget(
            name: "PlaydeckProtocolTests",
            dependencies: ["PlaydeckProtocol"],
            path: "Tests/PlaydeckProtocolTests"
        ),
    ]
)
