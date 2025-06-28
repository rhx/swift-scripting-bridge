// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "ScriptingBridge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftScriptingBridge",
            targets: ["SwiftScriptingBridge"]),
        .library(
            name: "SDEF",
            targets: ["SDEF"]),
        .executable(
            name: "sdef2swift",
            targets: ["sdef2swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftScriptingBridge"),
        .target(
            name: "SDEF",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]),
        .executableTarget(
            name: "sdef2swift",
            dependencies: [
                "SDEF",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(
            name: "SwiftScriptingBridgeTests",
            dependencies: ["SwiftScriptingBridge"]),
        .testTarget(
            name: "SDEFTests",
            dependencies: ["SDEF"]),
    ]
)
