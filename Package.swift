// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "container-compose-app",
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
    ],
    targets: [
        .executableTarget(
            name: "container-compose-app",
            dependencies: ["Yams"]),
    ]
)
