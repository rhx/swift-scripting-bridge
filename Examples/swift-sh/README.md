# Swift Scripting Bridge Examples using swift-sh

This directory contains simple example scripts demonstrating how to use swift-sh
to pull in swift-scripting-bridge dependencies for controlling macOS applications.

## About swift-sh

[swift-sh](https://github.com/mxcl/swift-sh) allows you to easily script
with third-party Swift packages by using inline dependency declarations.
It automatically fetches dependencies and manages the build process,
making Swift scripting as convenient as shell scripting.

## Installation

Install swift-sh using Homebrew:

```bash
brew install swift-sh
```

## Running the Examples

This directory contains several Swift scripts that demonstrate controlling macOS applications:

- `isFinderRunning.swift` - Check if Finder is running
- `MusicInfo.swift` - Display information about tracks and playlists in Music app
- `MusicPlayerControl.swift` - Control Music app playback
- `MusicPlaylistInfo.swift` - Get details about Music playlists
- `HowManyNotes.swift` - Count notes in the Notes app
- `NotesSearch.swift` - Search for notes in the Notes app
- `NotesAnalysis.swift` - Analyze notes content

To run an example:

```bash
swift sh MusicInfo.swift
# or make it executable and run directly:
chmod +x MusicInfo.swift
./MusicInfo.swift
```

## How It Works

Each script uses a special comment at the top to declare its dependencies:

```swift
#!/usr/bin/swift sh
import SwiftScriptingBridge // path/to/swift-scripting-bridge
```

When you run the script with `swift sh`, it automatically:
1. Downloads the swift-scripting-bridge package
2. Builds the dependencies
3. Runs your script with the imported modules available

This makes it easy to write powerful automation scripts without managing complex build configurations.
