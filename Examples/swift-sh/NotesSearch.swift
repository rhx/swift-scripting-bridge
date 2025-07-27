#!/usr/bin/env swift sh
import ScriptingBridge
import NotesScripting // rhx/swift-scripting-bridge ~> main
import Foundation

let app: Notes.Application? = SBApplication(bundleIdentifier: "com.apple.Notes")
guard let app else { fatalError("Could not access Notes") }

print("📝 Notes App Overview")
print("═════════════════════")

// Get basic stats
let totalNotes = app.notes.count
let accounts = app.accounts
let folders = app.folders

print("📊 Stats:")
print("   Total Notes: \(totalNotes)")
print("   Accounts: \(accounts.count)")
print("   Folders: \(folders.count)")

// Show accounts
print("\n🏦 Accounts:")
for account in accounts {
    let accountName = account.name
    let noteCount = account.notes.count
    print("   • \(accountName) (\(noteCount) notes)")
}

// Show folders
if folders.count > 0 {
    print("\n📁 Folders:")
    let maxFoldersToShow = min(10, folders.count)
    for i in 0..<maxFoldersToShow {
        let folder = folders[i]
        let folderName = folder.name
        let noteCount = folder.notes.count
        print("   • \(folderName) (\(noteCount) notes)")
    }
}

// Show recent notes
print("\n📝 Recent Notes:")
let maxNotesToShow = min(10, totalNotes)

for i in 0..<maxNotesToShow {
    let note = app.notes[i]
    let title = note.name ?? "Untitled Note"
    let bodyPreview = note.body.prefix(50)
    let cleanPreview = String(bodyPreview).replacingOccurrences(of: "\n", with: " ")

    // Show creation and modification dates if available
    var dateInfo = ""
    if let creationDate = note.creationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        dateInfo = " (created \(formatter.string(from: creationDate)))"
    }

    print("   • \(title)\(dateInfo)")
    if !cleanPreview.isEmpty {
        print("     \(cleanPreview)...")
    }

    // Show if note is shared
    let isShared = note.isShared ?? false
    if isShared {
        print("     🔗 Shared")
    }

    // Show if note is password protected
    let isPasswordProtected = note.isPasswordProtected ?? false
    if isPasswordProtected {
        print("     🔒 Password Protected")
    }
}

if totalNotes > maxNotesToShow {
    print("   ... and \(totalNotes - maxNotesToShow) more notes")
}

// Search for notes containing specific text
let searchTerm = "Swift"
print("\n🔍 Notes containing '\(searchTerm)':")

var foundNotes = 0
for note in app.notes {
    if note.body.localizedCaseInsensitiveContains(searchTerm) {
        let title = note.name ?? "Untitled Note"
        print("   • \(title)")
        foundNotes += 1
        if foundNotes >= 5 { break } // Limit search results
    }
}

if foundNotes == 0 {
    print("   No notes found containing '\(searchTerm)'")
} else if foundNotes >= 5 {
    print("   ... and potentially more (showing first 5)")
}
