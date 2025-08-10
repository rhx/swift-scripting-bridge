guard let app = Finder.application else { fatalError("Could not access Finder") }

if !app.isRunning {
    app.activate()
}

try? await Task.sleep(nanoseconds: 3_000_000_000)

app.windows.forEach { window in
    window.close()
}
