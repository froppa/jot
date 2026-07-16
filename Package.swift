// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShelfNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ShelfNote", targets: ["ShelfNote"])
    ],
    targets: [
        .executableTarget(name: "ShelfNote"),
        .testTarget(name: "ShelfNoteTests", dependencies: ["ShelfNote"])
    ]
)
