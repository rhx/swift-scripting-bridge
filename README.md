# Swift Scripting Bridge

A native Swift library and toolset for controlling scriptable macOS applications through the Scripting Bridge framework. The main tool, `sdef2swift`, generates type-safe Swift code directly from Apple Scripting Definition (`.sdef`) files.


There is also a build plugin for the
[Swift Package Manager (SPM)](https://www.swift.org/documentation/package-manager/)
that will convert `.sdef` files to Swift automatically.

## sdef2swift

A command-line tool that generates Swift Scripting Bridge code directly from Apple Scripting Definition (.sdef) files.  This tool was inspired by projects such as
[SwiftScripting](https://github.com/tingraldi/SwiftScripting) and
[ScriptingBridgeGen](https://github.com/417-72KI/ScriptingBridgeGen),
but unlike these projects, it uses pure Swift and does not require Python and llvm-swift
to convert Objective-C back to Swift.
Instead, it creates Swift code directly from an `SDEF` XML file.

### Overview

`sdef2swift` is similar to Apple's `sdp -f h` command,
but instead of generating Objective-C headers,
it produces Swift code that provides type-safe interfaces
for controlling scriptable macOS applications using the
Scripting Bridge framework.

### Features

- **Direct .sdef Processing**: Works directly with .sdef files without requiring intermediate Objective-C header generation
- **Type-Safe Swift Code**: Generates Swift protocols and enums with proper type safety
- **Comprehensive Support**: Handles classes, protocols, enumerations, properties, and inheritance
- **Clean Naming**: Converts Objective-C naming conventions to Swift-friendly names
- **Documentation Preservation**: Maintains descriptions and comments from the original .sdef
- **Recursive Generation**: Optionally generates separate files for included SDEF files (e.g., CocoaStandard.sdef)
- **Strongly Typed Extensions**: Generates typed accessor extensions for element arrays
- **Class Names Enumeration**: Optional generation of scripting class names enum
- **Bundle Identifier Support**: Generates convenience `application()` function when bundle ID is provided

### Installation

Build the tool using Swift Package Manager:

```bash
swift build -c release
```

The executable will be available at `.build/release/sdef2swift`.

### Usage

#### Basic Usage

```bash
sdef2swift /path/to/application.sdef
```

#### Advanced Options

```bash
sdef2swift [OPTIONS] <sdef-path>

ARGUMENTS:
  <sdef-path>             Path to the .sdef file to process

OPTIONS:
  -o, --output-directory  Output directory (default: current directory)
  -b, --basename         Base name for generated files (default: derived from sdef filename)
  -B, --bundle           Bundle identifier for the application. When provided, generates an application() convenience function
  -i, --include-hidden   Include hidden definitions marked in the sdef
  -v, --verbose          Enable verbose output
  -d, --debug            Enable debug output
  -r, --recursive        Recursively generate separate Swift files for included SDEF files
  -e, --generate-class-names-enum/--no-generate-class-names-enum
                         Generate a public enum of scripting class names (default: true)
  -x, --generate-strongly-typed-extensions/--no-generate-strongly-typed-extensions
                         Generate strongly typed accessor extensions for element arrays (default: true)
  -p, --prefixed         Generate prefixed typealiases for backward compatibility
  -f, --flat             Generate flat (unprefixed) typealiases, e.g. when compiling in a separate module
  -s, --search-path      Search path for .sdef files (colon-separated directories). Can be specified multiple times.
  -h, --help             Show help information
```

#### Examples

##### Simple Usage (with search paths)

Find and generate Swift code for Finder (searches standard macOS directories automatically):
```bash
sdef2swift Finder
```

Find Safari without specifying full path or .sdef extension:
```bash
sdef2swift Safari --output-directory ./Generated
```

##### Usage with full paths

Generate Swift code for Safari using full path:
```bash
sdef2swift /Applications/Safari.app/Contents/Resources/Safari.sdef
```

Generate with custom output directory and base name:
```bash
sdef2swift Safari.sdef --output-directory ./Generated --basename SafariScripting
```

Generate with bundle identifier for convenience function:
```bash
sdef2swift Music.sdef --bundle com.apple.Music --basename Music
```

This generates an `application()` function that simplifies app initialization:
```swift
// Instead of:
let app: Music.Application? = SBApplication(bundleIdentifier: "com.apple.Music")

// You can use:
let app = Music.application()
```

##### Search Path Examples

Use custom search paths (colon-separated):
```bash
sdef2swift --search-path /Applications:/System/Applications Safari
```

Use multiple search path options:
```bash
sdef2swift --search-path /Applications --search-path /custom/path Safari
```

Find apps in custom locations with verbose output:
```bash
sdef2swift --search-path /MyApps:/Applications MyApp --verbose
```

Generate with debug output for troubleshooting:
```bash
sdef2swift --debug Safari
```

##### Manual .sdef extraction

Extract .sdef from an application first, then generate Swift code:
```bash
sdef /System/Applications/Mail.app > Mail.sdef
sdef2swift Mail.sdef --verbose
```

### Search Path Feature

The `--search-path` option allows you to find `.sdef` files without specifying full paths. This feature automatically searches:

#### Default Search Paths

When no `--search-path` option is specified, sdef2swift searches these standard macOS directories:
- `.` (current directory)
- `/Applications`
- `/Applications/Utilities`
- `/System/Applications`
- `/System/Applications/Utilities`
- `/System/Library/CoreServices`
- `/Library/CoreServices`

#### Application Bundle Support

sdef2swift automatically searches inside application bundles at `Contents/Resources/` for `.sdef` files, so you can simply use:

```bash
sdef2swift Finder    # Finds /System/Library/CoreServices/Finder.app/Contents/Resources/Finder.sdef
sdef2swift Safari    # Finds /Applications/Safari.app/Contents/Resources/Safari.sdef
```

#### Extension Optional

You can omit the `.sdef` extension - the tool will search for both `AppName.sdef` and `AppName`:

```bash
sdef2swift Finder      # Searches for both "Finder.sdef" and "Finder"
sdef2swift Finder.sdef # Searches for both "Finder.sdef" and "Finder"
```

#### Bundle Identifier Support

When you provide a bundle identifier as input, sdef2swift intelligently searches for matching `.sdef` files:

```bash
sdef2swift com.apple.Music    # Finds com.apple.Music.sdef, falls back to Music.sdef
sdef2swift com.apple.Safari   # Finds Safari.sdef (since com.apple.Safari.sdef doesn't exist)
```

This is particularly useful with the build plugin, which uses `.sdefstub` files named with bundle identifiers.

**Note**: When using the build plugin, automatic SDEF extraction using `/usr/bin/sdef` may fail due to sandboxing restrictions. In such cases, extract the .sdef file manually:

```bash
sdef /System/Applications/TextEdit.app > TextEdit.sdef
```

#### Custom Search Paths

Specify custom directories to search:

```bash
# Single path with colon-separated directories
sdef2swift --search-path /MyApps:/Custom/Location AppName

# Multiple search path options
sdef2swift --search-path /MyApps --search-path /Another/Path AppName
```

### Generated Code Structure

The generated Swift code uses a namespace-based approach where all types are contained within an enum that acts as a namespace. This provides better organization and avoids naming conflicts.

### Namespace Approach (Default)

All generated types are contained within a namespace enum named after the basename:

```swift
public enum Safari {
    public typealias Application = SBApplication
    public typealias Object = SBObject
    public typealias ElementArray = SBElementArray

    @objc public enum SaveOptions: AEKeyword {
        case yes = 0x79657320
        case no = 0x6e6f2020
        case ask = 0x61736b20
    }

    public enum ClassNames {
        public static let application = "application"
        public static let document = "document"
        // ...
    }
}
```

## SPM Build Plugin

Swift Scripting Bridge includes a Swift Package Manager build plugin that automatically generates Swift interfaces from `.sdef` files during the build process. This eliminates the need to manually run `sdef2swift` and keeps your generated code up-to-date.

### Setup

Add the dependency and plugin to your `Package.swift`:

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: [
                .product(name: "SwiftScriptingBridge", package: "swift-scripting-bridge")
            ],
            plugins: [
                .plugin(name: "GenerateScriptingInterface", package: "swift-scripting-bridge")
            ]
        )
    ]
)
```

### Creating SDEF Files

The plugin automatically processes any `.sdef` and `.sdefstub` files in your target's `Sources` directory. You have three options:

#### 1. SDEF Stub Files (Recommended)

Create `.sdefstub` files with the application name or bundle identifier:

```bash
# Create stub files - plugin will find the real .sdef using search paths
touch Sources/MyApp/Notes.sdefstub
touch Sources/MyApp/Safari.sdefstub

# Or use bundle identifiers for automatic application() function generation
touch Sources/MyApp/com.apple.Music.sdefstub
touch Sources/MyApp/com.apple.Notes.sdefstub
```

The plugin will automatically locate the actual `.sdef` files using the same search logic as the command-line tool. When using bundle identifier naming (e.g., `com.apple.Music.sdefstub`), the plugin will:
- Extract the basename (e.g., "Music") for the generated Swift file
- Pass the bundle identifier to sdef2swift to generate a convenient `application()` function
- Search for both `com.apple.Music.sdef` and `Music.sdef` files

**Important**: Some applications (like TextEdit) don't include .sdef files in their bundles. For these apps, automatic extraction using `/usr/bin/sdef` may fail in the plugin environment due to sandboxing. In such cases, manually extract the .sdef file:

```bash
sdef /System/Applications/TextEdit.app > Sources/MyTarget/TextEdit.sdef
```

Then use `TextEdit.sdef` instead of `com.apple.TextEdit.sdefstub`.

#### 2. Symlinked SDEF Files

Create symlinks pointing to the actual `.sdef` files in application bundles:

```bash
cd Sources/MyApp
ln -sf /Applications/Safari.app/Contents/Resources/Safari.sdef Safari.sdef
ln -sf /System/Applications/Notes.app/Contents/Resources/Notes.sdef Notes.sdef
```

#### 3. Full SDEF Content

Copy or extract the full `.sdef` content into your project:

```bash
sdef /Applications/Safari.app > Sources/MyApp/Safari.sdef
```

### Build Process

When you run `swift build`, the plugin will:

1. Scan your target for `.sdef` and `.sdefstub` files
2. For each file:
   - If `.sdefstub`: Use search paths to find the real `.sdef` file
   - If empty `.sdef`: Use search paths to find the real `.sdef` file
   - If symlink: Follow the symlink to the target file
   - If regular file: Use the file content directly
3. Generate corresponding Swift interfaces (e.g., `Notes.sdefstub` → `Notes.swift`)
4. Include the generated Swift files in your target compilation

### Example Usage

After setting up the plugin, you can immediately use the generated interfaces,
e.g. in your main.swift:

```swift
import Foundation
import ScriptingBridge

let app: Notes.Application? = SBApplication(bundleIdentifier: "com.apple.Notes")
guard let app else { fatalError("Could not access Notes") }
print("Got \(app.notes.count) notes")
guard let firstNote = app.notes.first else { exit(EXIT_FAILURE)  }
print("First note: " + (firstNote.name ?? "<unnamed>"))
if let isShared = firstNote.isShared {
    print(isShared ? " is shared" : " is not shared")
}
if let body = firstNote.body {
    print(body)
}
if !(app.isActive ?? false) {
    app.activate()
}
app.windows.forEach { window in
    window.closeSaving?(.no, savingIn: nil)
}
```

### Generated Files Location

Generated Swift files are placed in the build directory and automatically included in compilation. You don't need to manage them manually - they're regenerated whenever the source `.sdef` files change.

### Plugin Advantages

- **Automatic Updates**: Generated code stays in sync with your `.sdef` files
- **Build Integration**: No manual steps required - just build your package
- **Search Path Support**: Works with empty `.sdefstub` files that trigger automatic `.sdef` discovery
- **Symlink Support**: Handle `.sdef` files in application bundles without copying
- **Clean Builds**: Generated files are properly tracked as build artifacts

## Using Generated Code

Once you have generated Swift code, you can use it in your projects. The generated interfaces support both Swift-style and Objective-C style property names for maximum flexibility:

```swift
import ScriptingBridge

@main
struct NotesMain {
    static func main() {
        // If using com.apple.Notes.sdefstub, you get a convenient application() function
        guard let app = Notes.application() else { 
            fatalError("Could not access Notes") 
        }
        
        // Or use the traditional approach:
        // let app: Notes.Application? = SBApplication(bundleIdentifier: "com.apple.Notes")
        print("Got \(app.notes.count) notes")
        guard let firstNote = app.notes.first else { return }
        print("First note: " + (firstNote.name ?? "<unnamed>"))

        // Swift-style property names (from Cocoa keys)
        if let isShared = firstNote.isShared {
            print("Swift style - isShared: \(isShared)")
        }
        if let body = firstNote.scriptingBody {
            print("Swift style - scriptingBody: \(body.prefix(50))...")
        }

        // Objective-C style property names (from SDEF names)
        if let shared = firstNote.shared {
            print("Objective-C style - shared: \(shared)")
        }
        if let body = firstNote.body {
            print("Objective-C style - body: \(body.prefix(50))...")
        }

        if !(app.isActive ?? false) {
            app.activate()
        }
        app.windows.forEach { window in
            window.closeSaving?(.no, savingIn: nil)
        }
    }
}
```

### Dual Naming Convention Support

The generated code provides property aliases so you can choose the naming style that fits your preference:

- **Swift-style names** (derived from Cocoa keys): `scriptingBody`, `isShared`, `scriptingDefaultFolder`
- **Objective-C style names** (derived from SDEF property names): `body`, `shared`, `defaultFolder`

Both naming conventions access the same underlying properties with proper `@objc` attribute mapping for ABI compatibility.

## Requirements

- macOS 13.0+
- Swift 6.1+
- Xcode command line tools (for XML processing)

## Dependencies

- [Swift Argument Parser](https://github.com/apple/swift-argument-parser) (1.2.0+)
- [SwiftSyntax](https://github.com/apple/swift-syntax) (510.0.0+)


## Licence

This project is licensed under the MIT Licence
(see main project licence file).
