#!/usr/bin/env swift sh
import ApplicationServices
import CoreServices
import ScriptingBridge
import TextEditScripting // rhx/swift-scripting-bridge ~> main

guard let textEdit = TextEdit.application else { fatalError("Cannot access TextEdit") }
if !textEdit.isRunning {
    textEdit.activate()
}
let textData = "Hello, world.".data(using: .utf8)!
let textDocumentType = FourCharCode("TEXT".utf8.reduce(0) { $0 << 8 + UInt32($1) })
guard let document = textEdit.make(new: textDocumentType, withData: textData) else {
    fatalError("Cannot create document.")
}
try? await Task.sleep(nanoseconds: 5_000_000_000)
document.close(saving: .no)
textEdit.quit()
