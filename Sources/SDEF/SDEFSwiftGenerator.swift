//
// SDEFSwiftGenerator.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

import Foundation

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
public final class SDEFSwiftGenerator {
    private let sdefURL: URL
    private let basename: String
    private let outputDirectory: String
    private let includeHidden: Bool
    private let generateClassNamesEnum: Bool
    private let shouldGenerateStronglyTypedExtensions: Bool
    private let shouldGenerateRecursively: Bool
    private let generatePrefixedTypealiases: Bool
    private let generateFlatTypealiases: Bool
    private let bundleIdentifier: String?
    private let verbose: Bool
    private let debug: Bool

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
    ///   - generateClassNamesEnum: Whether to generate an enum containing all scripting class names
    ///   - shouldGenerateStronglyTypedExtensions: Whether to generate strongly typed accessor extensions
    ///   - shouldGenerateRecursively: Whether to recursively generate files for included SDEF files
    ///   - generatePrefixedTypealiases: Whether to generate prefixed typealiases for backward compatibility
    ///   - generateFlatTypealiases: Whether to generate flat (unprefixed) typealiases
    ///   - bundleIdentifier: Optional bundle identifier for generating application() convenience function
    ///   - verbose: Whether to provide detailed logging during the generation process
    ///   - debug: Whether to provide debug logging during the generation process
    public init(sdefURL: URL, basename: String, outputDirectory: String, includeHidden: Bool, generateClassNamesEnum: Bool, shouldGenerateStronglyTypedExtensions: Bool, shouldGenerateRecursively: Bool, generatePrefixedTypealiases: Bool = false, generateFlatTypealiases: Bool = false, bundleIdentifier: String? = nil, verbose: Bool, debug: Bool = false) {
        self.sdefURL = sdefURL
        self.basename = basename
        self.outputDirectory = outputDirectory
        self.includeHidden = includeHidden
        self.generateClassNamesEnum = generateClassNamesEnum
        self.shouldGenerateStronglyTypedExtensions = shouldGenerateStronglyTypedExtensions
        self.shouldGenerateRecursively = shouldGenerateRecursively
        self.generatePrefixedTypealiases = generatePrefixedTypealiases
        self.generateFlatTypealiases = generateFlatTypealiases
        self.bundleIdentifier = bundleIdentifier
        self.verbose = verbose
        self.debug = debug
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
    /// - Returns: The URL of the main generated Swift source file
    /// - Throws: `RuntimeError` for any step that fails during the generation process
    public func generate() async throws -> URL {
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
        let parser = SDEFParser(document: xmlDocument, includeHidden: includeHidden, trackIncludes: shouldGenerateRecursively, verbose: verbose, debug: debug)
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
        if verbose {
            print("Generating Swift code for model with \(sdefModel.suites.count) suites")
            for suite in sdefModel.suites {
                print("  Suite '\(suite.name)' has \(suite.commands.count) commands")
            }
        }
        let codeGenerator = SDEFSwiftCodeGenerator(model: sdefModel, basename: basename, shouldGenerateClassNamesEnum: generateClassNamesEnum, shouldGenerateStronglyTypedExtensions: shouldGenerateStronglyTypedExtensions, generatePrefixedTypealiases: generatePrefixedTypealiases, generateFlatTypealiases: generateFlatTypealiases, bundleIdentifier: bundleIdentifier, verbose: verbose, debug: debug)
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

        // Process includes recursively if enabled
        if shouldGenerateRecursively {
            try await processIncludes(sdefModel.includes)
        }

        return outputURL
    }

    /// Processes included SDEF files and generates separate Swift files for each.
    ///
    /// When recursive generation is enabled, this method creates separate Swift files
    /// for each included SDEF file (such as CocoaStandard.sdef). This ensures that
    /// all definitions are available as separate modules and prevents duplicate
    /// definitions when multiple SDEF files include the same standard definitions.
    ///
    /// - Parameters:
    ///   - includes: Array of included SDEF files to process
    /// - Throws: `RuntimeError` if any included file cannot be processed
    private func processIncludes(_ includes: [SDEFInclude]) async throws {
        for include in includes {
            if verbose {
                print("Generating Swift code for included file: \(include.basename)")
            }

            // Generate Swift code for the included model
            // Note: Flat typealiases should only be generated for the main file, not included files
            // to avoid conflicts when multiple files are in the same directory
            let includeCodeGenerator = SDEFSwiftCodeGenerator(
                model: include.model,
                basename: include.basename,
                shouldGenerateClassNamesEnum: generateClassNamesEnum,
                shouldGenerateStronglyTypedExtensions: shouldGenerateStronglyTypedExtensions,
                generatePrefixedTypealiases: generatePrefixedTypealiases,
                generateFlatTypealiases: false, // Never generate flat typealiases for included files
                isIncludedFile: true,
                verbose: verbose,
                debug: debug
            )

            let includeSwiftCode: String
            do {
                includeSwiftCode = try includeCodeGenerator.generateCode()
            } catch {
                throw RuntimeError("Failed to generate Swift code for \(include.basename): \(error.localizedDescription)")
            }

            // Write the included Swift file
            let includeOutputURL = URL(fileURLWithPath: outputDirectory)
                .appendingPathComponent("\(include.basename).swift")

            do {
                try includeSwiftCode.write(to: includeOutputURL, atomically: true, encoding: .utf8)
                if verbose {
                    print("Generated Swift file: \(includeOutputURL.path)")
                }
            } catch {
                throw RuntimeError("Cannot write included output file \(include.basename).swift: \(error.localizedDescription)")
            }
        }
    }

    /// Validation errors that occur due to invalid command-line arguments or configuration.
    ///
    /// These errors indicate problems with user-provided input such as missing files,
    /// invalid file extensions, or configuration parameters that don't meet the tool's
    /// requirements. They are distinct from runtime errors that occur during processing.
    public struct ValidationError: Error, LocalizedError {
        private let message: String

        /// Creates a new validation error with the specified message.
        ///
        /// - Parameters:
        ///   - message: A descriptive message explaining what validation failed
        public init(_ message: String) {
            self.message = message
        }

        /// A localised description of the validation error suitable for display to users.
        public var errorDescription: String? {
            return message
        }
    }

    /// Runtime errors that occur during SDEF processing or Swift code generation.
    ///
    /// These errors indicate problems that occur during the execution of the generation
    /// process, such as file I/O failures, XML parsing errors, or code generation issues.
    /// They are distinct from validation errors which occur due to invalid user input.
    public struct RuntimeError: Error, LocalizedError {
        private let message: String

        /// Creates a new runtime error with the specified message.
        ///
        /// - Parameters:
        ///   - message: A descriptive message explaining what operation failed
        public init(_ message: String) {
            self.message = message
        }

        /// A localised description of the runtime error suitable for display to users.
        public var errorDescription: String? {
            return message
        }
    }
}
