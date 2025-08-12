// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SystemEventsScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "systemevents", targets: ["systemevents"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "systemevents",
            dependencies: [
                .product(name: "SwiftScriptingBridge", package: "swift-scripting-bridge")
            ],
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)
