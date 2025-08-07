// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "CalendarScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "calendar", targets: ["calendar"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "calendar",
            dependencies: [
                .product(name: "CalendarScripting", package: "swift-scripting-bridge")
            ],
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)
