#!/usr/bin/env swift sh
import ScriptingBridge
import MusicScripting // rhx/swift-scripting-bridge ~> main

let app: Music.Application? = SBApplication(bundleIdentifier: "com.apple.Music")
guard let app else { fatalError("Could not access the Music app") }

// Check if Music is running and show current status
if !app.isRunning {
    print("Music app is not running. Starting Music...")
    app.activate()
}

// Show current player state
let playerState = app.playerState
switch playerState {
case .some(.playing):
    print("Music is currently playing")
    if let track = app.currentTrack {
        print("Track: \(track.name ?? "Unknown") by \(track.artist ?? "Unknown Artist")")
        if let album = track.album {
            print("Album: \(album)")
        }
        if let position = app.playerPosition {
            print("Position: \(Int(position))s")
        }
    }
case .some(.paused):
    print("Music is paused")
case .some(.stopped):
    print("Music is stopped")
case .some(.fastforwarding):
    print("Music is fast forwarding")
case .some(.rewinding):
    print("Music is rewinding")
case .none:
    print("Unable to determine player state")
}

print("\nMusic library contains \(app.tracks.count) tracks in \(app.playlists.count) playlists")