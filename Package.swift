// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ActionLens",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ActionLensCore", targets: ["ActionLensCore"]),
        .executable(name: "ActionLensApp", targets: ["ActionLensApp"]),
        .executable(name: "actionlens", targets: ["ActionLensCLI"])
    ],
    targets: [
        .target(
            name: "ActionLensCore",
            dependencies: [],
            path: "Sources/ActionLensCore"
        ),
        .executableTarget(
            name: "ActionLensApp",
            dependencies: ["ActionLensCore"],
            path: "Sources/ActionLensApp"
        ),
        .executableTarget(
            name: "ActionLensCLI",
            dependencies: ["ActionLensCore"],
            path: "Sources/ActionLensCLI"
        )
    ],
    swiftLanguageModes: [.v5]
)
