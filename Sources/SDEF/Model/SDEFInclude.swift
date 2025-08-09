//
// SDEFInclude.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// Information about an included SDEF file that was processed during parsing.
///
/// When an SDEF file includes other definitions via xi:include directives, this structure
/// tracks the information needed to generate separate Swift files for the included content.
/// This enables modular code generation where shared definitions (such as those from
/// CocoaStandard.sdef) can be processed once and referenced across multiple generated
/// Swift files, maintaining consistency and reducing duplication.
///
/// The structure preserves both the original reference URL and the processed model,
/// allowing the code generator to create appropriate imports and references in the
/// final Swift output.
public struct SDEFInclude: Codable {
    /// The original href URL from the xi:include directive.
    ///
    /// This typically points to system-level SDEF files such as
    /// `file://localhost/System/Library/ScriptingDefinitions/CocoaStandard.sdef`.
    public let href: String

    /// The basename that should be used for the generated Swift file.
    ///
    /// This becomes the module name for the included definitions,
    /// allowing other generated code to import and reference these types.
    public let basename: String

    /// The model containing all definitions from the included file.
    ///
    /// This includes all suites, classes, enumerations, and commands
    /// defined in the included SDEF file, fully parsed and ready for
    /// code generation.
    public let model: SDEFModel

    /// Creates a new SDEF include reference with the specified components.
    ///
    /// This initialiser is typically called by the SDEF parser when processing
    /// xi:include directives in the source XML. The parser recursively processes
    /// included files, creating a complete model hierarchy.
    ///
    /// - Parameters:
    ///   - href: The original URL reference from the xi:include directive
    ///   - basename: The name to use for the generated Swift module
    ///   - model: The fully parsed model from the included SDEF file
    public init(href: String, basename: String, model: SDEFModel) {
        self.href = href
        self.basename = basename
        self.model = model
    }
}

