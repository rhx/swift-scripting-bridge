#!/usr/bin/env swift sh
import ScriptingBridge
import MusicScripting // rhx/swift-scripting-bridge ~> main

let app: Music.Application? = SBApplication(bundleIdentifier: "com.apple.Music")
guard let app else { fatalError("Could not access the Music app") }
print("Got \(app.tracks.count) tracks in \(app.playlists.count) playlists.")
guard let currentTrack = app.currentTrack else { exit(EXIT_SUCCESS)  }
print("Current track is '\(currentTrack.name ?? "<unknown>")' by " + (currentTrack.artist ?? "<unnamed>"))
