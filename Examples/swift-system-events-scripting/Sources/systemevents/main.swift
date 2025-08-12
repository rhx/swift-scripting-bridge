guard let system = SystemEvents.application else { fatalError("Could not access SystemEvents") }

// Sleep the system
system.sleep()

try? await Task.sleep(nanoseconds: 3_000_000_000)
