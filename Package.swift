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
        .plugin(
            name: "GenerateScriptingInterface",
            targets: ["GenerateScriptingInterface"]),
        .library(name: "CalendarScripting", targets: ["CalendarScripting"]),
        .library(name: "ConsoleScripting", targets: ["ConsoleScripting"]),
        .library(name: "ContactsScripting", targets: ["ContactsScripting"]),
        .library(name: "MailScripting", targets: ["MailScripting"]),
        .library(name: "MessagesScripting", targets: ["MessagesScripting"]),
        .library(name: "MusicScripting", targets: ["MusicScripting"]),
        .library(name: "NotesScripting", targets: ["NotesScripting"]),
        .library(name: "RemindersScripting", targets: ["RemindersScripting"]),
        .library(name: "SafariScripting", targets: ["SafariScripting"]),
        .library(name: "TextEditScripting", targets: ["TextEditScripting"]),
        .library(name: "TVScripting", targets: ["TVScripting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "SwiftScriptingBridge"),
        .target(
            name: "SDEF"),
        .executableTarget(
            name: "sdef2swift",
            dependencies: [
                "SDEF",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .target(name: "CalendarScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "ConsoleScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "ContactsScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "FinderScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "MailScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "MessagesScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "MusicScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "NotesScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "RemindersScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "SafariScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "TextEditScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .target(name: "TVScripting", dependencies: ["SwiftScriptingBridge"], plugins: ["GenerateScriptingInterface"]),
        .testTarget(
            name: "SwiftScriptingBridgeTests",
            dependencies: ["SwiftScriptingBridge"]),
        .testTarget(
            name: "SDEFTests",
            dependencies: ["SDEF", "sdef2swift"]),
        .plugin(
            name: "GenerateScriptingInterface",
            capability: .buildTool(),
            dependencies: ["sdef2swift"]),
    ]
)
