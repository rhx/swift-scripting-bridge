import Foundation

guard let music = Music.application else { fatalError("Could not access Tracks") }
print("Got \(music.tracks.count) tracks")
guard let firstTrack = music.tracks.first else { exit(EXIT_FAILURE)  }
print("First track: " + (firstTrack.name ?? "<unnamed>"))
if !music.isRunning {
    music.activate()
}
music.play()
try? await Task.sleep(nanoseconds: 5_000_000_000)
music.stop()
music.quit()
