//
// sdef2swift.swift
// sdef2swift
//
//  Created by Rene Hexel on 1/06/2024.
//  Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation
import ArgumentParser
import SDEF

/// A command-line tool that generates Swift Scripting Bridge code from Apple Scripting Definition files.
///
/// The `sdef2swift` tool processes .sdef XML files and produces clean, type-safe Swift code that provides
/// interfaces for controlling scriptable macOS applications through the Scripting Bridge framework.
/// Unlike Apple's `sdp -f h` command which generates Objective-C headers, this tool creates idiomatic
/// Swift code with proper type safety and modern Swift conventions.
///
/// The tool automatically handles XML includes (such as CocoaStandard.sdef), merges class extensions
/// with their base classes, and generates comprehensive Swift protocols that mirror the application's
/// scripting capabilities. The generated code includes enumerations for constant values, protocols
/// for each scriptable class, and extension methods that provide complete Swift interfaces.
///
/// ## Usage Examples
///
/// Generate Swift code for Safari:
/// ```bash
/// sdef2swift /Applications/Safari.app/Contents/Resources/Safari.sdef
/// ```
///
/// Generate with custom configuration:
/// ```bash
/// sdef2swift MyApp.sdef --output-directory ./Generated --basename MyAppScripting --verbose
/// ```
@main
struct SDEFToSwift: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sdef2swift",
        abstract: "Generate Swift Scripting Bridge code from .sdef files",
        discussion: """
        This tool parses Apple Scripting Definition (.sdef) files and generates
        Swift code for use with the Scripting Bridge framework, similar to 'sdp -f h'
        but outputting Swift instead of Objective-C headers.

        The generated Swift code provides type-safe interfaces for controlling
        scriptable applications using the macOS Scripting Bridge framework.
        """
    )

    /// The path to the SDEF file to process
    @Argument(help: "Path to the .sdef file to process")
    var sdefPath: String

    /// The output directory for generated files
    @Option(name: .shortAndLong, help: "Output directory (default: current directory)")
    var outputDirectory: String = "."

    /// The base name for generated files
    @Option(name: .shortAndLong, help: "Base name for generated files (default: derived from sdef filename)")
    var basename: String?

    /// Whether to include hidden definitions
    @Flag(name: .shortAndLong, help: "Include hidden definitions marked in the sdef")
    var includeHidden = false

    /// Whether to enable verbose output
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false

    /// Whether to generate class names enum
    @Flag(name: [.customShort("e", allowingJoined: true), .long], inversion: .prefixedNo, help: "Generate a public enum of scripting class names")
    var generateClassNamesEnum = true

    /// Whether to generate strongly typed extensions
    @Flag(name: [.customShort("x", allowingJoined: true), .long], inversion: .prefixedNo, help: "Generate strongly typed accessor extensions for element arrays")
    var generateStronglyTypedExtensions = true

    /// Whether to recursively generate files for included SDEF files
    @Flag(name: .shortAndLong, help: "Recursively generate separate Swift files for included SDEF files (e.g., CocoaStandard.sdef)")
    var recursive = false

    /// Whether to generate prefixed typealiases for backward compatibility
    @Flag(name: .shortAndLong, help: "Generate prefixed typealiases for types (e.g., AppNameClassName) that map to the namespaced types")
    var prefixed = false

    /// Whether to generate flat (unprefixed) typealiases
    @Flag(name: .shortAndLong, help: "Generate flat (unprefixed) typealiases for types, useful when using generated code as a separate module")
    var flat = false

    /// Search paths for .sdef files
    @Option(name: .shortAndLong, help: "Search path for .sdef files (colon-separated directories). Can be specified multiple times.")
    var searchPath: [String] = []

    /// Bundle identifier for the application
    @Option(name: [.customShort("B", allowingJoined: true), .long], help: "Bundle identifier for the application. When provided, generates an application() convenience function.")
    var bundle: String?

    /// Executes the main command logic to generate Swift code from the SDEF file.
    ///
    /// This method handles the complete workflow from validating input parameters to generating
    /// and writing the Swift output file. It validates the input file exists and has the correct
    /// extension, ensures the output directory is available, determines the appropriate base name
    /// for generated types, and coordinates the parsing and code generation process.
    ///
    /// The method provides comprehensive error handling and user feedback, including detailed
    /// progress information when verbose mode is enabled. All errors are properly categorised
    /// and presented with helpful messages to guide users in resolving configuration issues.
    ///
    /// - Throws: `ValidationError` for invalid input parameters, `RuntimeError` for processing failures
    func run() async throws {
        // Resolve the SDEF file path using search paths
        let (sdefURL, extractedBundleId) = try resolveSDEFPath(sdefPath)

        // Use extracted bundle ID if no bundle was explicitly provided
        let finalBundle = bundle ?? extractedBundleId

        if verbose {
            print("Resolved SDEF file: \(sdefURL.path)")
        }

        // Validate output directory
        let outputURL = URL(fileURLWithPath: outputDirectory)
        if !FileManager.default.fileExists(atPath: outputDirectory) {
            do {
                try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            } catch {
                throw SDEFSwiftGenerator.ValidationError("Cannot create output directory: \(outputDirectory)")
            }
        }

        // Determine base name
        let finalBasename = basename ?? sdefURL.deletingPathExtension().lastPathComponent.split(separator: ".").last.map { String($0) } ?? ""

        // Validate base name
        guard !finalBasename.isEmpty && finalBasename.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            throw SDEFSwiftGenerator.ValidationError("Invalid base name. Must contain only letters, numbers, and underscores.")
        }

        if verbose {
            print("Processing: \(sdefPath)")
            print("Base name: \(finalBasename)")
            print("Output directory: \(outputDirectory)")
        }

        do {
            let generator = SDEFSwiftGenerator(sdefURL: sdefURL, basename: finalBasename, outputDirectory: outputDirectory, includeHidden: includeHidden, generateClassNamesEnum: generateClassNamesEnum, shouldGenerateStronglyTypedExtensions: generateStronglyTypedExtensions, shouldGenerateRecursively: recursive, generatePrefixedTypealiases: prefixed, generateFlatTypealiases: flat, bundleIdentifier: finalBundle, verbose: verbose)
            let outputURL = try await generator.generate()
            print("Generated Swift file: \(outputURL.path)")

        } catch let error as SDEFSwiftGenerator.ValidationError {
            throw error
        } catch let error as SDEFSwiftGenerator.RuntimeError {
            throw error
        } catch {
            throw SDEFSwiftGenerator.RuntimeError("Failed to generate Swift code: \(error.localizedDescription)")
        }
    }

    /// Resolves the SDEF file path using search paths.
    ///
    /// This method implements comprehensive SDEF file resolution including:
    /// - Direct path checking (if path exists as-is)
    /// - Search path resolution with optional .sdef extension
    /// - Application bundle searching (Contents/Resources)
    /// - Default macOS application directories
    ///
    /// - Parameter path: The input path or filename to resolve
    /// - Returns: A URL pointing to the resolved SDEF file
    /// - Throws: `ValidationError` if the file cannot be found
    func resolveSDEFPath(_ path: String) throws -> (url: URL, extractedBundleId: String?) {
        // If it's an absolute path or contains path separators and exists, use it directly
        if path.hasPrefix("/") || path.contains("/") {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                guard url.pathExtension.lowercased() == "sdef" else {
                    throw SDEFSwiftGenerator.ValidationError("Input file must have .sdef extension")
                }
                return (url, nil)
            }
        }

        // Build search paths
        let searchPaths = getSearchPaths()

        // Extract base name (with or without .sdef extension)
        let baseName = path.hasSuffix(".sdef") ? String(path.dropLast(5)) : path
        var candidateNames = ["\(baseName).sdef", baseName]

        // If the baseName looks like a bundle ID (contains dots), also try just the app name
        if baseName.contains(".") {
            let appName = DefaultSearchPaths.extractBasename(from: baseName)
            candidateNames.append("\(appName).sdef")
            candidateNames.append(appName)
        }

        if verbose {
            print("Searching for: \(candidateNames)")
            print("Search paths: \(searchPaths)")
        }

        // Search through all paths
        for searchPath in searchPaths {
            for candidateName in candidateNames {
                // Direct file in search path
                let directPath = "\(searchPath)/\(candidateName)"
                if FileManager.default.fileExists(atPath: directPath) && directPath.hasSuffix(".sdef") {
                    return (URL(fileURLWithPath: directPath), nil)
                }

                // Search in .app bundles for .sdef files
                let apps = try? FileManager.default.contentsOfDirectory(atPath: searchPath)
                if let apps = apps {
                    for app in apps where app.hasSuffix(".app") {
                        let resourcesPath = "\(searchPath)/\(app)/Contents/Resources"
                        let sdefInApp = "\(resourcesPath)/\(candidateName)"
                        if FileManager.default.fileExists(atPath: sdefInApp) && sdefInApp.hasSuffix(".sdef") {
                            // If we found an .sdef in an app bundle and no bundle identifier was provided,
                            // try to extract the bundle identifier from the app for later use
                            if bundle == nil && !baseName.contains(".") {
                                let appPath = "\(searchPath)/\(app)"
                                let plistPath = "\(appPath)/Contents/Info.plist"

                                if FileManager.default.fileExists(atPath: plistPath),
                                   let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
                                   let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
                                   let extractedBundleId = plist["CFBundleIdentifier"] as? String {

                                    if verbose {
                                        print("Found .sdef in app bundle, extracted bundle ID: \(extractedBundleId)")
                                    }

                                    // Return the extracted bundle identifier
                                    return (URL(fileURLWithPath: sdefInApp), extractedBundleId)
                                }
                            }

                            return (URL(fileURLWithPath: sdefInApp), nil)
                        }
                    }
                }
            }
        }

        // If we couldn't find an .sdef file, try to find an application and extract its .sdef
        if verbose {
            print("Could not find .sdef file, attempting to extract from application")
        }

        // Try to find an application with a matching name or bundle ID
        var candidateBundleIds: [String] = []

        if baseName.contains(".") {
            // Already looks like a bundle ID
            candidateBundleIds.append(baseName)
        } else {
            // Try common bundle ID patterns
            candidateBundleIds.append("com.apple.\(baseName)")

            // Some apps have different names (e.g., Contacts -> AddressBook)
            let alternativeNames = ["Contacts": "AddressBook"]
            if let altName = alternativeNames[baseName] {
                candidateBundleIds.append("com.apple.\(altName)")
            }
        }

        for bundleId in candidateBundleIds {
            if let appSdef = try extractSDEFFromApplication(bundleIdentifier: bundleId, searchPaths: searchPaths) {
                return (appSdef, bundleId)
            }
        }

        // Provide helpful error message with suggestions
        var errorMessage = "SDEF file not found and could not extract from application: \(path)\n\n"
        errorMessage += "Suggestions:\n"
        errorMessage += "1. Use bundle identifier naming (e.g., com.apple.TextEdit.sdefstub instead of TextEdit.sdefstub)\n"
        errorMessage += "2. Extract the .sdef manually: sdef /System/Applications/TextEdit.app > TextEdit.sdef\n"
        errorMessage += "3. Create a real .sdef file instead of using .sdefstub\n"

        throw SDEFSwiftGenerator.ValidationError(errorMessage)
    }

    /// Extracts SDEF from an application using /usr/bin/sdef
    /// - Parameters:
    ///   - bundleIdentifier: The bundle identifier to search for
    ///   - searchPaths: The paths to search for the application
    /// - Returns: URL to a temporary file containing the extracted SDEF, or nil if extraction failed
    func extractSDEFFromApplication(bundleIdentifier: String, searchPaths: [String]) throws -> URL? {
        // First try to find the application by bundle ID
        var appPath = DefaultSearchPaths.findApplication(bundleIdentifier: bundleIdentifier)

        // If not found by bundle ID, try by name
        if appPath == nil {
            let appName = DefaultSearchPaths.extractBasename(from: bundleIdentifier)
            for searchPath in searchPaths {
                let candidatePath = "\(searchPath)/\(appName).app"
                if FileManager.default.fileExists(atPath: candidatePath) {
                    appPath = candidatePath
                    break
                }
            }
        }

        // If still not found and bundleIdentifier doesn't contain dots, try searching more broadly
        // and extract the actual bundle identifier from the app
        if appPath == nil && !bundleIdentifier.contains(".") {
            // Try to find any app with this name in search paths
            for searchPath in searchPaths {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: searchPath) {
                    for item in contents where item.hasSuffix(".app") {
                        let appBaseName = String(item.dropLast(4)) // Remove .app
                        if appBaseName.lowercased() == bundleIdentifier.lowercased() {
                            let candidatePath = "\(searchPath)/\(item)"
                            let plistPath = "\(candidatePath)/Contents/Info.plist"

                            // Try to extract the real bundle ID from the app
                            if FileManager.default.fileExists(atPath: plistPath),
                               let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
                               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
                               let realBundleId = plist["CFBundleIdentifier"] as? String {

                                if verbose {
                                    print("Found app \(item) with bundle ID: \(realBundleId)")
                                }

                                // Update the temp file name to use the real bundle ID
                                let tempDir = FileManager.default.temporaryDirectory
                                let tempFile = tempDir.appendingPathComponent("\(realBundleId).sdef")

                                // Run sdef with the found app path
                                return try runSDEFExtraction(appPath: candidatePath, outputFile: tempFile)
                            } else {
                                appPath = candidatePath
                                break
                            }
                        }
                    }
                    if appPath != nil { break }
                }
            }
        }

        guard let appPath = appPath else {
            if verbose {
                print("Could not find application for bundle ID: \(bundleIdentifier)")
                print("Searched in paths: \(searchPaths)")
            }
            return nil
        }

        // Use the normal extraction path for standard bundle IDs
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("\(bundleIdentifier).sdef")

        return try runSDEFExtraction(appPath: appPath, outputFile: tempFile)
    }

    /// Runs /usr/bin/sdef to extract SDEF from an application
    /// - Parameters:
    ///   - appPath: Path to the application
    ///   - outputFile: URL where to write the extracted SDEF
    /// - Returns: URL to the extracted SDEF file, or nil if extraction failed
    private func runSDEFExtraction(appPath: String, outputFile: URL) throws -> URL? {
        if verbose {
            print("Found application at: \(appPath)")
            print("Extracting SDEF using /usr/bin/sdef...")
        }

        // Run /usr/bin/sdef to extract the SDEF
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sdef")
        process.arguments = [appPath]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                if verbose {
                    print("sdef extraction failed with exit code: \(process.terminationStatus)")
                }
                return nil
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard !data.isEmpty else {
                if verbose {
                    print("sdef extraction returned empty data")
                }
                return nil
            }

            try data.write(to: outputFile)

            if verbose {
                print("Successfully extracted SDEF to: \(outputFile.path)")
            }

            return outputFile
        } catch {
            if verbose {
                print("Error extracting SDEF: \(error)")
                print("PATH: \(ProcessInfo.processInfo.environment["PATH"] ?? "not set")")
                print("This may be due to sandboxing restrictions in build plugins")
            }
            return nil
        }
    }

    /// Gets the list of search paths, combining user-specified paths with defaults.
    ///
    /// The search paths are constructed from:
    /// 1. User-specified --search-path options (colon-separated)
    /// 2. Default macOS application directories if no search paths specified
    ///
    /// - Returns: Array of directory paths to search
    func getSearchPaths() -> [String] {
        var paths: [String] = []

        // Process user-specified search paths (colon-separated)
        for pathSpec in searchPath {
            paths.append(contentsOf: pathSpec.split(separator: ":").map(String.init))
        }

        // If no search paths specified, use defaults
        if paths.isEmpty {
            paths = DefaultSearchPaths.paths
        }

        return paths.filter { FileManager.default.fileExists(atPath: $0) }
    }
}
