# Swift Scripting Bridge

Native Swift utilities and to aid in using Swift with the Scripting Bridge.



# sdef2swift

A command-line tool that generates Swift Scripting Bridge code directly from Apple Scripting Definition (.sdef) files.

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
sdef /Applications/Mail.app > Mail.sdef
sdef2swift Mail.sdef --verbose
```

## Generated Code Structure

The generated Swift file includes:

### Type Aliases
```swift
public typealias AppNameApplication = SBApplication
public typealias AppNameObject = SBObject
public typealias AppNameElementArray = SBElementArray
```

### Enumerations
```swift
@objc public enum AppNameSomeEnum: AEKeyword {
    case option1 = 0x6f707431
    case option2 = 0x6f707432
}
```

### Protocols for Classes
```swift
@objc public protocol AppNameSomeClass: SBObject {
    @objc optional var someProperty: String? { get set }
    @objc optional func someElements() -> SBElementArray
}

extension SBObject: AppNameSomeClass {}
```

### Application Protocol
```swift
@objc public protocol AppNameApplicationProtocol: SBApplicationProtocol {
    @objc optional func documents() -> SBElementArray
    @objc optional func windows() -> SBElementArray
}

extension SBApplication: AppNameApplicationProtocol {}
```

## Using Generated Code

Once you have generated Swift code, you can use it in your projects:

```swift
import ScriptingBridge

// Cast SBApplication to your generated application protocol
if let mail = SBApplication(bundleIdentifier: "com.apple.mail") as? MailApplicationProtocol {
    // Use type-safe methods and properties
    let accounts = mail.accounts?()
    // ...
}
```

## Comparison with Other Tools

| Tool | Input | Output | Direct Processing |
|------|-------|--------|------------------|
| `sdp -f h` | .sdef | Objective-C header | ✅ |
| `sbhc.py` / `SBHC.swift` | Objective-C header | Swift | ❌ |
| **`sdef2swift`** | .sdef | Swift | ✅ |

## Technical Details

### Supported SDEF Elements

- ✅ Suites
- ✅ Classes and class extensions
- ✅ Properties with all access modifiers
- ✅ Elements and element arrays
- ✅ Enumerations and enumerators
- ✅ Commands (basic support)
- ✅ Inheritance relationships
- ✅ Hidden element handling

### Type Mapping

| SDEF Type | Swift Type |
|-----------|------------|
| `text`, `string` | `String` |
| `integer`, `int` | `Int` |
| `real`, `double` | `Double` |
| `boolean`, `bool` | `Bool` |
| `date` | `Date` |
| `file`, `alias` | `URL` |
| `record` | `[String: Any]` |
| `any` | `Any` |
| Custom classes | `AppNameClassName` |

### Naming Conventions

- Class names: `AppNameClassName`
- Property names: `camelCase`
- Enum names: `AppNameEnumName`
- Enum cases: `camelCase`

## Requirements

- macOS 12.0+
- Swift 6.1+
- Xcode command line tools (for XML processing)

## Limitations

- Commands are parsed but not fully implemented in generated code
- Some complex SDEF features may require manual adjustment
- Generated code assumes use of the Scripting Bridge framework

## Contributing

This tool is part of the swift-scripting-bridge project. See the main project README for contribution guidelines.

## License

See the main project license file.