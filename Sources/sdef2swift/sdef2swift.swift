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
        let sdefURL = try resolveSDEFPath(sdefPath)

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
            let generator = SDEFSwiftGenerator(sdefURL: sdefURL, basename: finalBasename, outputDirectory: outputDirectory, includeHidden: includeHidden, generateClassNamesEnum: generateClassNamesEnum, shouldGenerateStronglyTypedExtensions: generateStronglyTypedExtensions, shouldGenerateRecursively: recursive, generatePrefixedTypealiases: prefixed, generateFlatTypealiases: flat, bundleIdentifier: bundle, verbose: verbose)
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
    func resolveSDEFPath(_ path: String) throws -> URL {
        // If it's an absolute path or contains path separators and exists, use it directly
        if path.hasPrefix("/") || path.contains("/") {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                guard url.pathExtension.lowercased() == "sdef" else {
                    throw SDEFSwiftGenerator.ValidationError("Input file must have .sdef extension")
                }
                return url
            }
        }

        // Build search paths
        let searchPaths = getSearchPaths()

        // Extract base name (with or without .sdef extension)
        let baseName = path.hasSuffix(".sdef") ? String(path.dropLast(5)) : path
        let candidateNames = ["\(baseName).sdef", baseName]

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
                    return URL(fileURLWithPath: directPath)
                }

                // Search in .app bundles for .sdef files
                let apps = try? FileManager.default.contentsOfDirectory(atPath: searchPath)
                if let apps = apps {
                    for app in apps where app.hasSuffix(".app") {
                        let resourcesPath = "\(searchPath)/\(app)/Contents/Resources"
                        let sdefInApp = "\(resourcesPath)/\(candidateName)"
                        if FileManager.default.fileExists(atPath: sdefInApp) && sdefInApp.hasSuffix(".sdef") {
                            return URL(fileURLWithPath: sdefInApp)
                        }
                    }
                }
            }
        }

        throw SDEFSwiftGenerator.ValidationError("SDEF file not found: \(path)")
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
            paths = [
                ".",
                "/Applications",
                "/Applications/Utilities",
                "/System/Applications",
                "/System/Applications/Utilities",
                "/System/Library/CoreServices",
                "/Library/CoreServices"
            ]
        }

        return paths.filter { FileManager.default.fileExists(atPath: $0) }
    }
}
