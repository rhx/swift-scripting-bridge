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
        let sdefURL = URL(fileURLWithPath: sdefPath)

        // Validate input file
        guard FileManager.default.fileExists(atPath: sdefPath) else {
            throw ValidationError("SDEF file not found: \(sdefPath)")
        }

        guard sdefURL.pathExtension.lowercased() == "sdef" else {
            throw ValidationError("Input file must have .sdef extension")
        }

        // Validate output directory
        let outputURL = URL(fileURLWithPath: outputDirectory)
        if !FileManager.default.fileExists(atPath: outputDirectory) {
            do {
                try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            } catch {
                throw ValidationError("Cannot create output directory: \(outputDirectory)")
            }
        }

        // Determine base name
        let finalBasename = basename ?? sdefURL.deletingPathExtension().lastPathComponent

        // Validate base name
        guard !finalBasename.isEmpty && finalBasename.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            throw ValidationError("Invalid base name. Must contain only letters, numbers, and underscores.")
        }

        if verbose {
            print("Processing: \(sdefPath)")
            print("Base name: \(finalBasename)")
            print("Output directory: \(outputDirectory)")
        }

        do {
            let generator = SDEFSwiftGenerator(
                sdefURL: sdefURL,
                basename: finalBasename,
                outputDirectory: outputDirectory,
                includeHidden: includeHidden,
                verbose: verbose
            )

            let outputURL = try await generator.generate()
            print("Generated Swift file: \(outputURL.path)")

        } catch let error as ValidationError {
            throw error
        } catch let error as RuntimeError {
            throw error
        } catch {
            throw RuntimeError("Failed to generate Swift code: \(error.localizedDescription)")
        }
    }
}

/// A comprehensive generator that coordinates SDEF parsing and Swift code generation.
///
/// The `SDEFSwiftGenerator` orchestrates the complete process of transforming an SDEF file
/// into Swift source code. It handles file I/O, XML parsing, SDEF model creation, Swift
/// code generation, and output file writing. The generator provides detailed error handling
/// and optional verbose logging throughout the process.
///
/// This class serves as the main coordination point between the SDEF library components,
/// ensuring that all steps in the generation pipeline are executed correctly and that
/// any errors are properly handled and reported to the user.
final class SDEFSwiftGenerator {
    private let sdefURL: URL
    private let basename: String
    private let outputDirectory: String
    private let includeHidden: Bool
    private let verbose: Bool

    /// Creates a new SDEF Swift generator with the specified configuration.
    ///
    /// The generator coordinates all aspects of the SDEF to Swift transformation process,
    /// from reading the input file to writing the generated output. All parameters are
    /// validated during the generation process to ensure they meet the requirements for
    /// successful code generation.
    ///
    /// - Parameters:
    ///   - sdefURL: The URL of the SDEF file to process
    ///   - basename: The prefix to use for all generated Swift types
    ///   - outputDirectory: The directory where the generated file should be written
    ///   - includeHidden: Whether to include definitions marked as hidden in the SDEF
    ///   - verbose: Whether to provide detailed logging during the generation process
    init(sdefURL: URL, basename: String, outputDirectory: String, includeHidden: Bool, verbose: Bool) {
        self.sdefURL = sdefURL
        self.basename = basename
        self.outputDirectory = outputDirectory
        self.includeHidden = includeHidden
        self.verbose = verbose
    }

    /// Generates Swift code from the SDEF file and writes it to the output directory.
    ///
    /// This method executes the complete generation pipeline: reading and parsing the SDEF XML,
    /// creating a structured model, generating Swift source code, and writing the result to
    /// the output file. Each step includes proper error handling and optional verbose logging.
    ///
    /// The generation process handles XML includes automatically, merges class extensions with
    /// their base classes, and produces comprehensive Swift code that includes all necessary
    /// protocols, enumerations, and type definitions for complete Scripting Bridge integration.
    ///
    /// - Returns: The URL of the generated Swift source file
    /// - Throws: `RuntimeError` for any step that fails during the generation process
    func generate() async throws -> URL {
        // Parse the SDEF file
        let xmlData: Data
        do {
            xmlData = try Data(contentsOf: sdefURL)
        } catch {
            throw RuntimeError("Cannot read SDEF file: \(error.localizedDescription)")
        }

        let xmlDocument: XMLDocument
        do {
            xmlDocument = try XMLDocument(data: xmlData, options: [])
        } catch {
            throw RuntimeError("Invalid XML in SDEF file: \(error.localizedDescription)")
        }

        if verbose {
            print("Parsed SDEF XML successfully")
        }

        // Create the parser and parse the model
        let parser = SDEF.parser(for: xmlDocument, includeHidden: includeHidden, verbose: verbose)
        let sdefModel: SDEFModel
        do {
            sdefModel = try parser.parse()
        } catch {
            throw RuntimeError("Failed to parse SDEF structure: \(error.localizedDescription)")
        }

        if verbose {
            print("Extracted \(sdefModel.suites.count) suites")
            let totalClasses = sdefModel.suites.reduce(0) { $0 + $1.classes.count }
            let totalEnums = sdefModel.suites.reduce(0) { $0 + $1.enumerations.count }
            print("Found \(totalClasses) classes and \(totalEnums) enumerations")
        }

        // Generate Swift code
        let codeGenerator = SDEF.swiftGenerator(for: sdefModel, basename: basename, verbose: verbose)
        let swiftCode: String
        do {
            swiftCode = try codeGenerator.generateCode()
        } catch {
            throw RuntimeError("Failed to generate Swift code: \(error.localizedDescription)")
        }

        // Write to output file
        let outputURL = URL(fileURLWithPath: outputDirectory)
            .appendingPathComponent("\(basename).swift")

        do {
            try swiftCode.write(to: outputURL, atomically: true, encoding: .utf8)
        } catch {
            throw RuntimeError("Cannot write output file: \(error.localizedDescription)")
        }

        return outputURL
    }
}

/// Validation errors that occur due to invalid command-line arguments or configuration.
///
/// These errors indicate problems with user-provided input such as missing files,
/// invalid file extensions, or configuration parameters that don't meet the tool's
/// requirements. They are distinct from runtime errors that occur during processing.
struct ValidationError: Error, LocalizedError {
    private let message: String

    /// Creates a new validation error with the specified message.
    ///
    /// - Parameters:
    ///   - message: A descriptive message explaining what validation failed
    init(_ message: String) {
        self.message = message
    }

    /// A localised description of the validation error suitable for display to users.
    var errorDescription: String? {
        return message
    }
}

/// Runtime errors that occur during SDEF processing or Swift code generation.
///
/// These errors indicate problems that occur during the execution of the generation
/// process, such as file I/O failures, XML parsing errors, or code generation issues.
/// They are distinct from validation errors which occur due to invalid user input.
struct RuntimeError: Error, LocalizedError {
    private let message: String

    /// Creates a new runtime error with the specified message.
    ///
    /// - Parameters:
    ///   - message: A descriptive message explaining what operation failed
    init(_ message: String) {
        self.message = message
    }

    /// A localised description of the runtime error suitable for display to users.
    var errorDescription: String? {
        return message
    }
}
