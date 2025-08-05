#!/usr/bin/env swift sh
import ApplicationServices
import CoreServices
import ScriptingBridge
import TextEditScripting // rhx/swift-scripting-bridge ~> main

guard let textEdit = TextEdit.application else { fatalError("Cannot access TextEdit") }

if !textEdit.isRunning {
    textEdit.activate()
}

let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_textedit.txt")
try "Hello, world!".write(to: tempURL, atomically: true, encoding: .utf8)

guard let document = textEdit.open(tempURL) else {
    fatalError("Cannot open document.")
}

try? await Task.sleep(nanoseconds: 5_000_000_000)
document.close()
textEdit.quit()
try FileManager.default.removeItem(at: tempURL)
