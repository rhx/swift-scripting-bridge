# SwiftScripting Notes Example

This is a simple example that uses [swift-scripting-bridge](https://github.com/rhx/swift-scripting-bridge)
to interact with the Notes application.

## Dependency

This package currently depends on being in the Examples folder of the Swift Scripting Bridge.
To use this package as a template, uncomment the following line in `Package.swift`:

```Swift
        .package(url: "https://github.com/rhx/swift-scripting-bridge", branch: "main"),
```
and remove the line that reads:
```Swift
        .package(path: "../..")
```
