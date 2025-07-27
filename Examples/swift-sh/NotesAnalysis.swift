#!/usr/bin/env swift sh
import ScriptingBridge
import NotesScripting // rhx/swift-scripting-bridge ~> main
import Foundation

let app: Notes.Application? = SBApplication(bundleIdentifier: "com.apple.Notes")
guard let app else { fatalError("Could not access Notes") }

print("📝 Notes App Analysis")
print("═════════════════════")

// Get basic stats
let totalNotes = app.notes.count
let accounts = app.accounts

print("📊 Overview:")
print("   Total Notes: \(totalNotes)")
print("   Accounts: \(accounts.count)")

// Show accounts and their notes
print("\n🏦 Accounts:")
for account in accounts {
    let accountName = account.name ?? "Unknown Account"
    let noteCount = account.notes.count
    print("   • \(accountName): \(noteCount) notes")
}

// Show some recent notes with details
print("\n📄 Recent Notes (first 5):")
let maxToShow = min(5, totalNotes)

for i in 0..<maxToShow {
    let note = app.notes[i]
    let title = note.name ?? "Untitled Note"
    let body = note.body ?? ""
    let preview = String(body.prefix(80)).replacingOccurrences(of: "\n", with: " ")
    
    print("   \(i+1). \(title)")
    if !preview.isEmpty {
        print("      \(preview)...")
    }
    
    // Show creation date if available
    if let creationDate = note.creationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        print("      Created: \(formatter.string(from: creationDate))")
    }
    
    // Show additional properties
    if let isShared = note.isShared, isShared {
        print("      🔗 Shared")
    }
    if let isPasswordProtected = note.isPasswordProtected, isPasswordProtected {
        print("      🔒 Password Protected")
    }
    print("")
}

if totalNotes > maxToShow {
    print("   ... and \(totalNotes - maxToShow) more notes")
}
