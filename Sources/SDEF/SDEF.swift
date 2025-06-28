//
// SDEF.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// A comprehensive library for parsing and processing Apple Scripting Definition (.sdef) files.
///
/// The SDEF library provides tools for parsing XML-based scripting definition files,
/// extracting structured data models, and generating Swift code that provides type-safe
/// interfaces for controlling scriptable macOS applications through the Scripting Bridge framework.
///
/// This library handles the complete workflow from raw SDEF XML to generated Swift code,
/// including processing of external includes (such as CocoaStandard.sdef), merging of
/// class extensions, and generation of idiomatic Swift protocols and enumerations.
///
/// ## Usage
///
/// ```swift
/// import SDEF
///
/// // Parse an SDEF file
/// let url = URL(fileURLWithPath: "MyApp.sdef")
/// let xmlData = try Data(contentsOf: url)
/// let xmlDocument = try XMLDocument(data: xmlData)
///
/// let parser = SDEFParser(document: xmlDocument, includeHidden: false, verbose: true)
/// let model = try parser.parse()
///
/// // Generate Swift code
/// let generator = SDEFSwiftCodeGenerator(model: model, basename: "MyApp", verbose: true)
/// let swiftCode = try generator.generateCode()
/// ```
public enum SDEFLibrary {
    /// The current version of the SDEF library
    public static let version = "1.0.0"
}

public extension SDEFLibrary {
    /// Creates a parser for the specified SDEF document.
    ///
    /// This convenience method creates a properly configured SDEF parser that can process
    /// the provided XML document. The parser handles XI:Include directives, merges class
    /// extensions with their base classes, and provides comprehensive error handling.
    ///
    /// - Parameters:
    ///   - document: The XML document containing SDEF content
    ///   - includeHidden: Whether to include definitions marked as hidden
    ///   - verbose: Whether to enable detailed parsing output
    /// - Returns: A configured SDEF parser ready to process the document
    static func parser(for document: XMLDocument, includeHidden: Bool = false, verbose: Bool = false) -> SDEFParser {
        return SDEFParser(document: document, includeHidden: includeHidden, verbose: verbose)
    }

    /// Creates a Swift code generator for the specified SDEF model.
    ///
    /// This convenience method creates a code generator that transforms the parsed SDEF
    /// model into clean, type-safe Swift code suitable for use with the Scripting Bridge
    /// framework. The generated code follows Swift best practices and naming conventions.
    ///
    /// - Parameters:
    ///   - model: The parsed SDEF model to generate code from
    ///   - basename: The prefix to use for all generated Swift types
    ///   - verbose: Whether to enable detailed generation output
    /// - Returns: A configured code generator ready to produce Swift code
    static func swiftGenerator(for model: SDEFModel, basename: String, shouldGenerateClassNamesEnum: Bool = true, verbose: Bool = false) -> SDEFSwiftCodeGenerator {
        return SDEFSwiftCodeGenerator(model: model, basename: basename, shouldGenerateClassNamesEnum: shouldGenerateClassNamesEnum, verbose: verbose)
    }

    /// Creates a comprehensive Swift generator that coordinates SDEF parsing and code generation.
    ///
    /// This convenience method creates a generator that handles the complete workflow from
    /// SDEF file to generated Swift code, including file I/O, XML parsing, model creation,
    /// and code generation. It provides a high-level interface for processing SDEF files.
    ///
    /// - Parameters:
    ///   - sdefURL: The URL of the SDEF file to process
    ///   - basename: The prefix to use for all generated Swift types
    ///   - outputDirectory: The directory where the generated file should be written
    ///   - includeHidden: Whether to include definitions marked as hidden in the SDEF
    ///   - generateClassNamesEnum: Whether to generate an enum containing all scripting class names
    ///   - verbose: Whether to provide detailed logging during the generation process
    /// - Returns: A configured SDEF Swift generator ready to process the file
    static func generator(for sdefURL: URL, basename: String, outputDirectory: String, includeHidden: Bool = false, generateClassNamesEnum: Bool = true, verbose: Bool = false) -> SDEFSwiftGenerator {
        return SDEFSwiftGenerator(sdefURL: sdefURL, basename: basename, outputDirectory: outputDirectory, includeHidden: includeHidden, generateClassNamesEnum: generateClassNamesEnum, verbose: verbose)
    }

    /// Parses an SDEF file and generates Swift code in a single operation.
    ///
    /// This convenience method combines parsing and code generation into a single step,
    /// handling the complete workflow from SDEF XML to generated Swift source code.
    /// It's ideal for simple use cases where you want to process an SDEF file directly
    /// without intermediate processing steps.
    ///
    /// - Parameters:
    ///   - url: The URL of the SDEF file to process
    ///   - basename: The prefix to use for generated Swift types
    ///   - includeHidden: Whether to include hidden definitions
    ///   - generateClassNamesEnum: Whether to generate an enum containing all scripting class names
    ///   - verbose: Whether to enable detailed output
    /// - Returns: The generated Swift source code as a string
    /// - Throws: `SDEFParsingError` if parsing fails, `SDEFCodeGenerationError` if code generation fails, or file system errors
    static func generateSwiftCode(from url: URL, basename: String, includeHidden: Bool = false, generateClassNamesEnum: Bool = true, verbose: Bool = false) throws -> String {
        let xmlData = try Data(contentsOf: url)
        let xmlDocument = try XMLDocument(data: xmlData, options: [])

        let parser = SDEFParser(document: xmlDocument, includeHidden: includeHidden, verbose: verbose)
        let model = try parser.parse()

        let generator = SDEFSwiftCodeGenerator(model: model, basename: basename, shouldGenerateClassNamesEnum: generateClassNamesEnum, verbose: verbose)
        return try generator.generateCode()
    }
}
