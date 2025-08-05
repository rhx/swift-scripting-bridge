import ScriptingBridge
import TextEditScripting

guard let app = TextEdit.application else { fatalError("Could not access TextEdit") }

print("📝 TextEdit App Analysis")
print("═══════════════════════")

// Get basic stats
let documents = app.documents
print("📊 Overview:")
print("   Open Documents: \(documents.count)")

if documents.count > 0 {
    print("\n📄 Documents:")
    let maxToShow = min(3, documents.count)
    
    for i in 0..<maxToShow {
        let document = documents[i]
        let name = document.name ?? "Untitled"
        let modified = document.modified ?? false
        let hasPath = document.path != nil
        
        print("   • \(name)")
        if modified {
            print("     📝 Modified")
        }
        if hasPath {
            print("     💾 Saved")
        } else {
            print("     📄 Unsaved")
        }
    }
    
    if documents.count > maxToShow {
        print("   ... and \(documents.count - maxToShow) more documents")
    }
} else {
    print("\n📄 No documents currently open")
}

print("\nTextEdit is \(app.isRunning ? "running" : "not running")")

// Try to get some properties of the application
if let frontmost = app.frontmost {
    print("TextEdit is \(frontmost ? "in the foreground" : "in the background")")
}

if let version = app.version {
    print("TextEdit version: \(version)")
}
