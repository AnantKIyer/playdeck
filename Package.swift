// swift-tools-version: 5.9
// Root package — builds PlaydeckProtocol on macOS / Linux (Swift 5.9+).
// Full PlaydeckMac / PlaydeckiOS app targets require Xcode on macOS (see README).
import PackageDescription

let package = Package(
    name: "Playdeck",
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
            path: "Packages/PlaydeckProtocol/Sources/PlaydeckProtocol"
        ),
        .testTarget(
            name: "PlaydeckProtocolTests",
            dependencies: ["PlaydeckProtocol"],
            path: "Packages/PlaydeckProtocol/Tests/PlaydeckProtocolTests"
        ),
    ]
)
