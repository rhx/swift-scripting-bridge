// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinderScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "finder", targets: ["finder"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "finder",
            dependencies: [
                .product(name: "SwiftScriptingBridge", package: "swift-scripting-bridge")
            ],
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)
