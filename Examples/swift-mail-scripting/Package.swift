// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MailScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "mail", targets: ["mail"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "mail",
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)