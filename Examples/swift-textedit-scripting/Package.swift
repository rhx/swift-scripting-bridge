// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TextEditScripting",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable( name: "textedit", targets: ["textedit"])
    ],
    dependencies: [
        // .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "textedit",
            dependencies: [
                .product(name: "TextEditScripting", package: "swift-scripting-bridge")
            ],
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
        ])
    ]
)
