// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrackMyCursor",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TrackMyCursor", targets: ["TrackMyCursorApp"])
    ],
    targets: [
        .target(
            name: "TrackMyCursor",
            path: "Sources/TrackMyCursor"
        ),
        .executableTarget(
            name: "TrackMyCursorApp",
            dependencies: ["TrackMyCursor"],
            path: "Sources/TrackMyCursorApp"
        ),
        .testTarget(
            name: "TrackMyCursorTests",
            dependencies: ["TrackMyCursor"],
            path: "Tests/TrackMyCursorTests"
        )
    ]
)
