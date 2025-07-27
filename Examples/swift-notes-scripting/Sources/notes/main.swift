import Foundation
import ScriptingBridge

let app: Notes.Application? = SBApplication(bundleIdentifier: "com.apple.Notes")
guard let app else { fatalError("Could not access Notes") }
print("Got \(app.notes.count) notes")
guard let firstNote = app.notes.first else { exit(EXIT_FAILURE)  }
print("First note: " + (firstNote.name ?? "<unnamed>"))
if let isShared = firstNote.isShared {
    print(isShared ? " is shared" : " is not shared")
}
if let body = firstNote.body {
    print(body)
}
if !(app.isActive ?? false) {
    app.activate()
}
app.windows.forEach { window in
    window.closeSaving?(.no, savingIn: nil)
}
