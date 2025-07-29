// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MusicScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "music", targets: ["music"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "music",
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)
