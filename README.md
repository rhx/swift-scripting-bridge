# Swift Scripting Bridge

A native Swift library and toolset for controlling scriptable macOS applications through the Scripting Bridge framework. The main tool, `sdef2swift`, generates type-safe Swift code directly from Apple Scripting Definition (`.sdef`) files.


# sdef2swift

A command-line tool that generates Swift Scripting Bridge code directly from Apple Scripting Definition (.sdef) files.  This tool was inspired by projects such as
[SwiftScripting](https://github.com/tingraldi/SwiftScripting) and
[ScriptingBridgeGen](https://github.com/417-72KI/ScriptingBridgeGen),
but unlike these projects, it uses pure Swift and does not require Python and llvm-swift
to convert Objective-C back to Swift.
Instead, it creates Swift code directly from an `SDEF` XML file.

## Overview

`sdef2swift` is similar to Apple's `sdp -f h` command,
but instead of generating Objective-C headers,
it produces Swift code that provides type-safe interfaces
for controlling scriptable macOS applications using the
Scripting Bridge framework.

## Features

- **Direct .sdef Processing**: Works directly with .sdef files without requiring intermediate Objective-C header generation
- **Type-Safe Swift Code**: Generates Swift protocols and enums with proper type safety
- **Comprehensive Support**: Handles classes, protocols, enumerations, properties, and inheritance
- **Clean Naming**: Converts Objective-C naming conventions to Swift-friendly names
- **Documentation Preservation**: Maintains descriptions and comments from the original .sdef
- **Recursive Generation**: Optionally generates separate files for included SDEF files (e.g., CocoaStandard.sdef)
- **Strongly Typed Extensions**: Generates typed accessor extensions for element arrays
- **Class Names Enumeration**: Optional generation of scripting class names enum

## Installation

Build the tool using Swift Package Manager:

```bash
swift build -c release
```

The executable will be available at `.build/release/sdef2swift`.

## Usage

### Basic Usage

```bash
sdef2swift /path/to/application.sdef
```

### Advanced Options

```bash
sdef2swift [OPTIONS] <sdef-path>

ARGUMENTS:
  <sdef-path>             Path to the .sdef file to process

OPTIONS:
  -o, --output-directory  Output directory (default: current directory)
  -b, --basename         Base name for generated files (default: derived from sdef filename)
  -i, --include-hidden   Include hidden definitions marked in the sdef
  -v, --verbose          Enable verbose output
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

### Examples

#### Simple Usage (with search paths)

Find and generate Swift code for Finder (searches standard macOS directories automatically):
```bash
sdef2swift Finder
```

Find Safari without specifying full path or .sdef extension:
```bash
sdef2swift Safari --output-directory ./Generated
```

#### Traditional Usage (full paths)

Generate Swift code for Safari using full path:
```bash
sdef2swift /Applications/Safari.app/Contents/Resources/Safari.sdef
```

Generate with custom output directory and base name:
```bash
sdef2swift Safari.sdef --output-directory ./Generated --basename SafariScripting
```

#### Search Path Examples

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

#### Manual .sdef extraction

Extract .sdef from an application first, then generate Swift code:
```bash
sdef /System/Applications/Mail.app > Mail.sdef
sdef2swift Mail.sdef --verbose
```

## Search Path Feature

The `--search-path` option allows you to find `.sdef` files without specifying full paths. This feature automatically searches:

### Default Search Paths

When no `--search-path` option is specified, sdef2swift searches these standard macOS directories:
- `.` (current directory)
- `/Applications`
- `/Applications/Utilities`
- `/System/Applications`
- `/System/Applications/Utilities`
- `/System/Library/CoreServices`
- `/Library/CoreServices`

### Application Bundle Support

sdef2swift automatically searches inside application bundles at `Contents/Resources/` for `.sdef` files, so you can simply use:

```bash
sdef2swift Finder    # Finds /System/Library/CoreServices/Finder.app/Contents/Resources/Finder.sdef
sdef2swift Safari    # Finds /Applications/Safari.app/Contents/Resources/Safari.sdef
```

### Extension Optional

You can omit the `.sdef` extension - the tool will search for both `AppName.sdef` and `AppName`:

```bash
sdef2swift Finder      # Searches for both "Finder.sdef" and "Finder"
sdef2swift Finder.sdef # Searches for both "Finder.sdef" and "Finder"
```

### Custom Search Paths

Specify custom directories to search:

```bash
# Single path with colon-separated directories
sdef2swift --search-path /MyApps:/Custom/Location AppName

# Multiple search path options
sdef2swift --search-path /MyApps --search-path /Another/Path AppName
```

## Generated Code Structure

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

### Compatibility Options

- **`--prefixed`**: Generates prefixed typealiases for backward compatibility (e.g., `SafariApplication`)
- **`--flat`**: Generates unprefixed typealiases for when using the code as a separate module

## Using Generated Code

Once you have generated Swift code, you can use it in your projects, e.g.:

```swift
import ScriptingBridge

@main
struct NotesMain {
    static func main() {
        // Using the namespace approach
        let notesApp: NotesApplication? = SBApplication(bundleIdentifier: "com.apple.Notes")
        guard let notesApp else { fatalError("Could not access Notes") }

        // Access properties and elements
        let notes = notesApp.notesNotes
        print("Got \(notes.count) notes")

        guard let firstNote = notes.first else { return }
        print("First note: " + (firstNote.name ?? "<unnamed>"))

        if let isShared = firstNote.isShared {
            print(isShared  ? " is shared" : " is not shared")
        }

        if let body = firstNote.scriptingBody {
            print(body)
        }

        if !(notesApp.isActive ?? false) {
            notesApp.activate()
        }
    }
}
```

### With Namespace (new default)

```swift
// Types are now accessed through the namespace
let saveOption: Safari.SaveOptions = .yes
let elementArray: Safari.ElementArray = safariApp.windows()
```

### With --prefixed option (backward compatibility)

```swift
// Traditional prefixed approach
let saveOption: SafariSaveOptions = .yes
let elementArray: SafariElementArray = safariApp.windows()
```

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
