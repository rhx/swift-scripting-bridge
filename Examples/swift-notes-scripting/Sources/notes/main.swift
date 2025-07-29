guard let app = Notes.application else { fatalError("Could not access Notes") }
print("Got \(app.notes.count) notes")

if let firstNote = app.notes.first {
    print("First note: " + (firstNote.name ?? "<unnamed>"), terminator: "")
    print(firstNote.isShared ? " is shared" : " is not shared")
    print(firstNote.body ?? "")
}

if !app.isActive {
    app.activate()
    app.openNoteLocation("notes://")
}

try? await Task.sleep(nanoseconds: 3_000_000_000)

app.windows.forEach { window in
    window.close()
}
app.quit()
