//
// SDEFEnumeration.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// An enumeration type that defines a set of named constant values.
///
/// SDEF enumerations define sets of predefined constant values that provide symbolic
/// names for specific Apple Event codes used throughout the scripting interface. These
/// enumerations enable type-safe programming by restricting property values and command
/// parameters to well-defined sets of constants, improving both code reliability and
/// documentation clarity.
///
/// Each enumeration contains a collection of enumerators, where each enumerator represents
/// a specific constant value with its own four-character Apple Event code. The enumeration
/// system maps human-readable symbolic names to the underlying codes used in Apple Event
/// communication, making scripts more readable and maintainable while preserving the
/// precise semantics required by the Apple Event system.
public struct SDEFEnumeration: Codable {
    /// The name of this enumeration type.
    ///
    /// This name is used in scripting dictionaries and code generation
    /// to identify the enumeration. It should be descriptive and indicate
    /// the purpose or domain of the constant values it contains.
    public let name: String

    /// The four-character Apple Event code that identifies this enumeration.
    ///
    /// This unique identifier is used by the Apple Event system to reference
    /// the enumeration type in type specifications and command parameters.
    /// The code must be exactly four characters and should be registered to avoid conflicts.
    public let code: String

    /// An optional description of what this enumeration represents.
    ///
    /// This description appears in scripting dictionaries and helps users
    /// understand the purpose and scope of the constant values. It should
    /// clearly explain what aspect of the application the enumeration covers.
    public let description: String?

    /// The constant values defined within this enumeration.
    ///
    /// This collection contains all the named constants that belong to this
    /// enumeration type. Each enumerator defines a specific value that can
    /// be used wherever this enumeration type is expected.
    public let enumerators: [SDEFEnumerator]

    /// Whether this enumeration is marked as hidden in the scripting interface.
    ///
    /// Hidden enumerations are not exposed in the application's scripting dictionary
    /// and cannot be accessed through normal scripting mechanisms. This is typically
    /// used for internal or deprecated enumeration types.
    public let isHidden: Bool

    /// Creates a new enumeration with the specified enumerators.
    ///
    /// This initialiser constructs a complete enumeration definition that encapsulates
    /// a set of related constant values. The enumeration serves as a type-safe container
    /// for symbolic constants that can be used throughout the scripting interface,
    /// providing both human-readable names and the underlying Apple Event codes needed
    /// for system communication.
    ///
    /// - Parameters:
    ///   - name: The name of the enumeration type
    ///   - code: The four-character Apple Event code
    ///   - description: Optional description of the enumeration
    ///   - enumerators: The constant values within this enumeration
    ///   - isHidden: Whether the enumeration is hidden from normal use
    public init(name: String, code: String, description: String?, enumerators: [SDEFEnumerator], isHidden: Bool) {
        self.name = name
        self.code = code
        self.description = description
        self.enumerators = enumerators
        self.isHidden = isHidden
    }
}

/// A single constant value within an enumeration.
///
/// Enumerators represent the individual named constants within an enumeration type,
/// providing symbolic names for specific Apple Event codes that can be used as property
/// values or command parameters. Each enumerator encapsulates both the human-readable
/// name and the underlying four-character code that the Apple Event system uses for
/// communication with the target application.
///
/// Enumerators may also include additional metadata such as string values that enable
/// integration with Cocoa binding mechanisms, allowing for seamless translation between
/// different representation formats used by various parts of the scripting infrastructure.
/// This flexibility ensures that enumeration values can be used effectively across
/// different contexts while maintaining consistent semantics.
public struct SDEFEnumerator: Codable {
    /// The name of this constant value.
    ///
    /// This symbolic name provides a human-readable identifier for the constant
    /// that can be used in scripts and generated code. It should be descriptive
    /// and follow standard naming conventions for the target language.
    public let name: String

    /// The four-character Apple Event code that identifies this enumerator.
    ///
    /// This unique code is used by the Apple Event system to represent the
    /// constant value in inter-application communication. The code must be
    /// exactly four characters and should be unique within its enumeration.
    public let code: String

    /// An optional description of what this constant represents.
    ///
    /// This description appears in scripting dictionaries and helps users
    /// understand the meaning and appropriate usage of the constant value.
    /// It should clearly explain when and why this particular value would be used.
    public let description: String?

    /// An optional string value used for Cocoa binding purposes.
    ///
    /// This string provides an alternative representation of the constant that
    /// integrates with Cocoa's binding mechanisms. It enables translation between
    /// different representation formats used across the scripting infrastructure.
    public let stringValue: String?

    /// Creates a new enumerator with the specified attributes.
    ///
    /// This initialiser constructs a complete constant definition that maps a symbolic
    /// name to an Apple Event code, with optional metadata for enhanced integration.
    /// The enumerator serves as a bridge between human-readable scripting interfaces
    /// and the underlying code-based Apple Event system, ensuring both usability and
    /// precise system communication.
    ///
    /// - Parameters:
    ///   - name: The name of the constant value
    ///   - code: The four-character Apple Event code
    ///   - description: Optional description of the constant
    ///   - stringValue: Optional string value for Cocoa bindings
    public init(name: String, code: String, description: String?, stringValue: String?) {
        self.name = name
        self.code = code
        self.description = description
        self.stringValue = stringValue
    }
}

