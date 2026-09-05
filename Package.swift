// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacSubsystemForAndroid",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "msa-daemon", targets: ["MSADaemon"]),
        .executable(name: "msa-cli", targets: ["MSACLI"]),
        .library(name: "MSACore", targets: ["MSACore"])
    ],
    targets: [
        .target(
            name: "MSACore",
            dependencies: [],
            path: "Sources/MSACore"
        ),
        .executableTarget(
            name: "MSADaemon",
            dependencies: ["MSACore"],
            path: "Sources/MSADaemon"
        ),
        .executableTarget(
            name: "MSACLI",
            dependencies: ["MSACore"],
            path: "Sources/MSACLI"
        )
    ]
)
