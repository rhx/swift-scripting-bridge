// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "NotesScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "notes", targets: ["notes"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "notes",
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)
