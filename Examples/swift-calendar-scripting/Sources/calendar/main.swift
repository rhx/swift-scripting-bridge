import CalendarScripting

guard let app = ICal.application else { fatalError("Could not access Calendar") }
print("Got \(app.calendars.count) calendars")

if let firstCalendar = app.calendars.first {
    print("First calendar: " + (firstCalendar.name ?? "<unnamed>"))
}

if !app.isActive {
    app.activate()
}

try? await Task.sleep(nanoseconds: 3_000_000_000)

app.windows.forEach { window in
    window.close()
}
app.close()
