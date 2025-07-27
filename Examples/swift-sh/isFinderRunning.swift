#!/usr/bin/env swift sh
import SwiftScriptingBridge // rhx/swift-scripting-bridge ~> main
import ScriptingBridge

let finderApp = SBApplication(bundleIdentifier: "com.apple.finder")
print("Finder is \(finderApp?.isRunning ?? false ? "running" : "not running")")
