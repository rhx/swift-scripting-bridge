//
// SDEFModel.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// A complete SDEF (Scripting Definition) model representing the structure of an Apple Scripting Definition file.
///
/// The `SDEFModel` serves as the root container for all scripting definitions parsed from an .sdef XML file.
/// It organises the scripting interface into logical suites, each containing classes, enumerations, and commands
/// that define how external applications can interact with a scriptable macOS application through Apple Events.
///
/// The model structure mirrors the hierarchical organisation of SDEF XML files, where suites group related
/// functionality, classes define scriptable objects with their properties and elements, enumerations provide
/// constant values, and commands specify the actions that can be performed. This hierarchical structure
/// enables efficient code generation and maintains the semantic relationships between different components
/// of the scripting interface.
///
/// Standard classes from CocoaStandard.sdef are maintained separately to allow proper inheritance and
/// extension mechanisms, where application-specific classes can extend standard behaviour without
/// duplicating definitions.
public struct SDEFModel: Codable {
    /// The scripting suites contained within this SDEF model.
    ///
    /// Each suite represents a logical grouping of related scripting functionality,
    /// such as the Standard Suite for common operations or application-specific
    /// suites for specialised features.
    public let suites: [SDEFSuite]

    /// The standard classes loaded from CocoaStandard.sdef.
    ///
    /// These provide base functionality that applications can extend,
    /// including common classes like window, document, and application.
    /// Keeping these separate allows proper handling of class extensions
    /// and inheritance hierarchies.
    public let standardClasses: [SDEFClass]

    /// Information about included SDEF files that were processed.
    ///
    /// This tracks any xi:include directives that were resolved during parsing,
    /// enabling modular code generation where shared definitions can be
    /// referenced rather than duplicated.
    public let includes: [SDEFInclude]

    /// Creates a new SDEF model with the specified components.
    ///
    /// This initialiser assembles a complete scripting definition model from its constituent parts.
    /// The model represents the entire scripting interface for an application, including both
    /// application-specific definitions and any standard or included definitions.
    ///
    /// - Parameters:
    ///   - suites: The scripting suites defined in the main SDEF file
    ///   - standardClasses: Classes from CocoaStandard.sdef or other standard definitions
    ///   - includes: References to any included SDEF files that were processed
    public init(suites: [SDEFSuite], standardClasses: [SDEFClass] = [], includes: [SDEFInclude] = []) {
        self.suites = suites
        self.standardClasses = standardClasses
        self.includes = includes
    }
}
