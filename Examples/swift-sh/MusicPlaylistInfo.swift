#!/usr/bin/env swift sh
import ScriptingBridge
import MusicScripting // rhx/swift-scripting-bridge ~> main

let app: Music.Application? = SBApplication(bundleIdentifier: "com.apple.Music")
guard let app else { fatalError("Could not access the Music app") }

print("🎵 Music Library Overview")
print("═══════════════════════════")

// Library statistics
let totalTracks = app.tracks.count
let totalPlaylists = app.playlists.count

print("📊 Library Stats:")
print("   Tracks: \(totalTracks)")
print("   Playlists: \(totalPlaylists)")

// Show current track if playing
if let currentTrack = app.currentTrack {
    print("\n🎧 Currently Playing:")
    print("   Track: \(currentTrack.name ?? "Unknown")")
    print("   Artist: \(currentTrack.artist ?? "Unknown")")
    print("   Album: \(currentTrack.album ?? "Unknown")")
    if let year = currentTrack.year, year > 0 {
        print("   Year: \(year)")
    }
    if let genre = currentTrack.genre {
        print("   Genre: \(genre)")
    }
}

// Show some playlists
print("\n📃 Playlists:")
let playlists = app.playlists
let maxPlaylistsToShow = min(10, totalPlaylists)

for i in 0..<maxPlaylistsToShow {
    let playlist = playlists[i]
    let trackCount = playlist.tracks.count
    let name = playlist.name ?? "Unnamed Playlist"
    let duration = playlist.duration ?? 0

    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60

    print("   • \(name) (\(trackCount) tracks, \(minutes):\(String(format: "%02d", seconds)))")

    // Show a few tracks from the playlist
    if trackCount > 0 {
        let maxTracksToShow = min(3, trackCount)
        for j in 0..<maxTracksToShow {
            let track = playlist.tracks[j]
            let trackName = track.name ?? "Unknown Track"
            let artist = track.artist ?? "Unknown Artist"
            print("     ↳ \(trackName) - \(artist)")
        }
        if trackCount > 3 {
            print("     ↳ ... and \(trackCount - 3) more tracks")
        }
    }
}

if totalPlaylists > maxPlaylistsToShow {
    print("   ... and \(totalPlaylists - maxPlaylistsToShow) more playlists")
}

// Show some recent tracks
print("\n🆕 Recent Tracks:")
let tracks = app.tracks
let maxTracksToShow = min(5, totalTracks)

for i in 0..<maxTracksToShow {
    let track = tracks[i]
    let name = track.name ?? "Unknown Track"
    let artist = track.artist ?? "Unknown Artist"
    let album = track.album ?? "Unknown Album"
    print("   • \(name) - \(artist) (\(album))")
}

if totalTracks > maxTracksToShow {
    print("   ... and \(totalTracks - maxTracksToShow) more tracks")
}
