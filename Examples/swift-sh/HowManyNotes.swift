#!/usr/bin/env swift sh
import ScriptingBridge
import NotesScripting // rhx/swift-scripting-bridge ~> main

guard let app = Notes.application else { fatalError("Could not access Notes") }
print("Got \(app.notes.count) notes")
guard let firstNote = app.notes.first else { exit(EXIT_SUCCESS)  }
print("First note: " + (firstNote.name ?? "<unnamed>"), terminator: "")
let isShared = firstNote.isShared ?? false
print(isShared ? " is shared" : " is not shared")
