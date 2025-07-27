import Foundation
import ScriptingBridge

let app: Mail.Application? = SBApplication(bundleIdentifier: "com.apple.Mail")
guard let app else { fatalError("Could not access Mail") }

print("📧 Mail App Analysis")
print("═══════════════════")

// Get basic stats
let accounts = app.accounts
print("📊 Overview:")
print("   Accounts: \(accounts.count)")

// Show accounts
print("\n📮 Mail Accounts:")
for account in accounts {
    let accountName = account.name ?? "Unknown Account"
    let mailboxCount = account.mailboxes.count
    print("   • \(accountName): \(mailboxCount) mailboxes")
}

// Show some mailboxes
if let firstAccount = accounts.first {
    let mailboxes = firstAccount.mailboxes
    let maxToShow = min(5, mailboxes.count)
    
    print("\n📦 Mailboxes in \(firstAccount.name ?? "First Account"):")
    for i in 0..<maxToShow {
        let mailbox = mailboxes[i]
        let name = mailbox.name ?? "Unknown Mailbox"
        let messageCount = mailbox.messages.count
        print("   • \(name): \(messageCount) messages")
    }
    
    if mailboxes.count > maxToShow {
        print("   ... and \(mailboxes.count - maxToShow) more mailboxes")
    }
}

print("\nMail app is \(app.isRunning ? "running" : "not running")")