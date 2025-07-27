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
  -h, --help             Show help information
```

### Examples

Generate Swift code for Safari:
```bash
sdef2swift /Applications/Safari.app/Contents/Resources/Safari.sdef
```

Generate with custom output directory and base name:
```bash
sdef2swift Safari.sdef --output-directory ./Generated --basename SafariScripting
```

Extract .sdef from an application first, then generate Swift code:
```bash
sdef /System/Applications/Mail.app > Mail.sdef
sdef2swift Mail.sdef --verbose
```

## Using Generated Code

Once you have generated Swift code, you can use it in your projects, e.g.:

```swift
import ScriptingBridge

@main
struct NotesMain {
    static func main() {
        let notesApp: NotesApplication? = SBApplication(bundleIdentifier: "com.apple.Notes")
        guard let notesApp else { fatalError("Could not access Notes") }
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