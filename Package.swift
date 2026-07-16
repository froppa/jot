// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Jot",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Jot", targets: ["Jot"])
    ],
    targets: [
        .executableTarget(name: "Jot"),
        .testTarget(name: "JotTests", dependencies: ["Jot"])
    ]
)
