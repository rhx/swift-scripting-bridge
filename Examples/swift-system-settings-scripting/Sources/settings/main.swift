guard let app = SystemPreferences.application else { fatalError("Could not access SystemPreferences") }

if !app.isActive {
    app.activate()
}

let panes = app.panes
print("Got \(panes.count) panes:")

for (i, pane) in panes.enumerated() {
    let anchors = pane.anchors
    let paneID = "<" + (pane.id ?? "Pane \(i)") + ">"
    let title: String
    if pane.navigationTitle.isEmpty {
        title = paneID
    } else {
        title = pane.navigationTitle + " " + paneID
    }
    print(String(format: "%02d: " + title + " - \(anchors.count) anchors:", i))
    for (j, anchor) in anchors.enumerated() {
        print(String(format: "    %02d: " + (anchor.name ?? "<nil>"), j))
        if j > 20 {
            print("    ...")
            break
        }
    }
    if pane.navigationTitle == "Menu Bar" {
        app.currentPane = pane
    }
}

if let activePane = app.currentPane {
    print("")
    print("Active pane: " + (activePane.id ?? "<nil>"))
}


//
//try? await Task.sleep(nanoseconds: 3_000_000_000)
//
//app.windows.forEach { window in
//    window.close()
//}
