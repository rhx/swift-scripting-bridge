//
// SDEFSuite.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// A scripting suite that groups related classes, enumerations, and commands together.
///
/// In Apple's scripting architecture, suites provide logical groupings for related functionality.
/// Each suite represents a cohesive domain of scripting capabilities, such as text manipulation,
/// file operations, or application-specific features. For example, a "Text Suite" might contain
/// classes for documents, paragraphs, and words, along with commands for text manipulation.
///
/// The suite structure enables modular organisation of complex scripting interfaces, allowing
/// applications to separate concerns and provide clear boundaries between different functional
/// areas. Each suite has a unique four-character code that identifies it in the Apple Event
/// system, enabling precise routing of scripting commands and property accesses.
///
/// Suites can also extend classes defined in other suites through class extensions, providing
/// a mechanism for adding suite-specific functionality without modifying the original class
/// definitions. This promotes reusability and maintains clean separation of responsibilities
/// across the scripting interface.
public struct SDEFSuite: Codable, Sendable {
    /// The human-readable name of this scripting suite.
    ///
    /// This name identifies the suite in documentation and scripting dictionaries.
    /// Examples include "Standard Suite", "Text Suite", or application-specific
    /// names like "Mail Suite" or "Safari Suite".
    public let name: String

    /// The four-character Apple Event code that uniquely identifies this suite.
    ///
    /// This code is used by the Apple Event system to route scripting commands
    /// and property accesses to the correct suite. The code must be exactly
    /// four characters and should be registered with Apple to avoid conflicts.
    public let code: String

    /// An optional description explaining the purpose and functionality of this suite.
    ///
    /// This description appears in scripting dictionaries and helps users understand
    /// what capabilities the suite provides. It should clearly explain the domain
    /// of functionality covered by the suite.
    public let description: String?

    /// The scriptable classes defined within this suite.
    ///
    /// These represent the scriptable objects that the suite introduces,
    /// such as documents, windows, or application-specific entities.
    /// Each class defines properties and elements that can be accessed
    /// through the scripting interface.
    public let classes: [SDEFClass]

    /// The enumeration types available within this suite.
    ///
    /// Enumerations provide sets of named constants that can be used as
    /// property values or command parameters. They map symbolic names to
    /// four-character codes used in Apple Events.
    public let enumerations: [SDEFEnumeration]

    /// The scriptable commands that can be executed within this suite.
    ///
    /// Commands represent the actions that can be performed through the
    /// scripting interface. Each command may have parameters and a return
    /// value, defining how external scripts can invoke application functionality.
    public let commands: [SDEFCommand]

    /// Extensions to classes defined in other suites, adding suite-specific functionality.
    ///
    /// Class extensions allow this suite to augment classes that may be defined
    /// in other suites without modifying their original definitions. This mechanism
    /// supports modular composition of scripting functionality.
    public let classExtensions: [SDEFClassExtension]

    /// Creates a new scripting suite with the specified components.
    ///
    /// This initialiser constructs a complete suite definition from its constituent parts.
    /// The suite serves as a logical container for related scripting functionality,
    /// organising classes, enumerations, and commands that work together to provide
    /// a coherent set of scripting capabilities. The four-character code must be unique
    /// within the application's scripting definition and should follow Apple's conventions.
    ///
    /// - Parameters:
    ///   - name: The human-readable name of the suite
    ///   - code: The four-character Apple Event code for the suite
    ///   - description: Optional description of the suite's purpose
    ///   - classes: Classes defined within this suite
    ///   - enumerations: Enumeration types defined within this suite
    ///   - commands: Commands available within this suite
    ///   - classExtensions: Extensions to classes from other suites
    public init(name: String, code: String, description: String?, classes: [SDEFClass], enumerations: [SDEFEnumeration], commands: [SDEFCommand], classExtensions: [SDEFClassExtension]) {
        self.name = name
        self.code = code
        self.description = description
        self.classes = classes
        self.enumerations = enumerations
        self.commands = commands
        self.classExtensions = classExtensions
    }
}
