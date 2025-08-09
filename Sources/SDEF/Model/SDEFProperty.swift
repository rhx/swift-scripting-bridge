//
// SDEFProperty.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// A property of a scriptable class that can be read or modified through scripting.
///
/// Properties represent the attributes of scriptable objects that can be accessed and
/// potentially modified through Apple Events. Each property encapsulates both the data
/// type information and access control characteristics that govern how external scripts
/// can interact with the attribute. Properties form the primary interface for reading
/// and writing object state through the scripting system.
///
/// The property definition includes a four-character Apple Event code that uniquely
/// identifies the property in scripting commands, a type specification that defines
/// the expected data format, and access permissions that may restrict operations to
/// read-only, write-only, or full read-write access. Properties may also include
/// Cocoa key names that enable better integration with modern Swift naming conventions.
public struct SDEFProperty: Codable, Sendable {
    /// The human-readable name of this property.
    ///
    /// This name is used in scripting dictionaries and code generation
    /// to identify the property. It should be descriptive and follow
    /// standard naming conventions for the target language.
    public let name: String

    /// The four-character Apple Event code that identifies this property.
    ///
    /// This unique identifier is used by the Apple Event system to
    /// reference the property in scripting commands. The code must be
    /// exactly four characters and should be registered to avoid conflicts.
    public let code: String

    /// The data type and constraints for this property's value.
    ///
    /// This specification defines what kind of data the property can hold,
    /// whether it contains single values or lists, and whether the value
    /// can be nil. It governs type checking and conversion in the scripting system.
    public let type: SDEFPropertyType

    /// An optional description of what this property represents.
    ///
    /// This description appears in scripting dictionaries and helps users
    /// understand the purpose and semantics of the property. It should clearly
    /// explain what aspect of the object the property represents.
    public let description: String?

    /// The access permissions for this property (read, write, or both).
    ///
    /// This string specifies how scripts can interact with the property.
    /// Common values include "r" (read-only), "w" (write-only), or "rw" (read-write).
    /// If nil, the property defaults to read-write access.
    public let access: String?

    /// The Cocoa key name for this property, used for generating better Swift property names.
    ///
    /// This key provides an alternative name that follows Cocoa naming conventions,
    /// enabling the generation of more idiomatic Swift property names that integrate
    /// naturally with modern Swift code. If not specified, the standard name is used.
    public let cocoaKey: String?

    /// Whether this property is marked as hidden in the scripting interface.
    ///
    /// Hidden properties are not exposed in the application's scripting dictionary
    /// and cannot be accessed through normal scripting mechanisms. This is typically
    /// used for internal or deprecated properties.
    public let isHidden: Bool

    /// Creates a new property with the specified attributes.
    ///
    /// This initialiser constructs a complete property definition that encapsulates all
    /// aspects of a scriptable attribute. The property serves as a bridge between the
    /// object's internal state and the external scripting interface, providing controlled
    /// access to object data with appropriate type safety and access restrictions.
    ///
    /// - Parameters:
    ///   - name: The human-readable name of the property
    ///   - code: The four-character Apple Event code
    ///   - type: The data type and constraints for the property
    ///   - description: Optional description of the property
    ///   - access: Access permissions string, or nil for read-write
    ///   - cocoaKey: The Cocoa key name, or nil if not specified
    ///   - isHidden: Whether the property is hidden from normal use
    public init(name: String, code: String, type: SDEFPropertyType, description: String? = nil, access: String? = nil, cocoaKey: String? = nil, isHidden: Bool = false) {
        self.name = name
        self.code = code
        self.type = type
        self.description = description
        self.access = access
        self.cocoaKey = cocoaKey
        self.isHidden = isHidden
    }
}

/// A child object collection that a class can contain.
///
/// Elements represent the types of child objects that can be contained within a parent object,
/// forming the hierarchical structure of the application's object model. Each element definition
/// specifies a relationship where the parent class can contain multiple objects of a specific
/// child type. For example, a document might contain paragraph elements, an application might
/// contain window elements, or a folder might contain file elements.
///
/// Elements enable navigation through the object hierarchy using scripting commands, allowing
/// scripts to access collections of related objects and perform operations on them. The element
/// definition may include a Cocoa key path that specifies how to access the collection in the
/// underlying implementation, enabling efficient bridging between the scripting interface and
/// the application's internal object model.
public struct SDEFElement: Codable, Sendable {
    /// The name of the class type that can be contained as an element.
    ///
    /// This must match the name of a class defined in the SDEF, specifying
    /// what type of objects can appear in this element collection. The type
    /// determines the properties and operations available on collection members.
    public let type: String

    /// The Cocoa key path used to access this collection of elements.
    ///
    /// This key path specifies how to retrieve the collection from the parent
    /// object in the underlying implementation. It enables efficient bridging
    /// between the scripting interface and the application's object model.
    public let cocoaKey: String?

    /// Creates a new element specification.
    ///
    /// This initialiser defines a parent-child relationship in the object hierarchy,
    /// specifying that objects of the parent class can contain collections of objects
    /// of the specified type. The element specification enables hierarchical navigation
    /// through the scripting interface and defines how collections are accessed.
    ///
    /// - Parameters:
    ///   - type: The class type that can be contained
    ///   - cocoaKey: The Cocoa key path for accessing elements, or nil if not specified
    public init(type: String, cocoaKey: String?) {
        self.type = type
        self.cocoaKey = cocoaKey
    }
}

/// The data type specification for a property, including whether it's a list or optional.
///
/// Property types define the expected data format and constraints for property values,
/// providing comprehensive type information that governs how the scripting system handles
/// data conversion, validation, and storage. The type specification includes the fundamental
/// data type (such as text, integer, boolean, or a custom class name), collection semantics
/// that determine whether the property holds single values or lists, and nullability
/// constraints that specify whether the property value can be nil.
///
/// This type information enables the code generation system to produce appropriate Swift
/// types and accessor methods, ensuring type safety and providing clear interfaces for
/// scripting interactions. The type specification also supports rich documentation that
/// helps users understand the expected data format and constraints.
public struct SDEFPropertyType: Codable, Sendable {
    /// The fundamental data type for this property.
    ///
    /// This string specifies the base type that the property can hold,
    /// such as "text", "integer", "boolean", "date", or the name of a custom class.
    /// The type determines how values are converted and validated in the scripting system.
    public let baseType: String

    /// Whether this property contains a list of values rather than a single value.
    ///
    /// When true, the property represents a collection of values of the base type.
    /// This affects code generation and determines whether the property uses
    /// array types and collection access patterns.
    public let isList: Bool

    /// Whether this property's value can be nil.
    ///
    /// This flag determines whether the property must always have a value
    /// or can be nil. It affects code generation by controlling whether
    /// optional types are used in the generated Swift interface.
    public let isOptional: Bool

    /// Optional description of what this property represents.
    ///
    /// This description provides additional context about the property type,
    /// explaining constraints, expected formats, or special behaviours that
    /// may not be obvious from the base type alone.
    public let description: String?

    /// Creates a new property type specification.
    ///
    /// This initialiser constructs a complete type definition that encapsulates all
    /// the information needed for type-safe code generation and runtime type checking.
    /// The type specification serves as the foundation for generating appropriate Swift
    /// types and determining how values are converted between the scripting system and
    /// the application's internal data structures.
    ///
    /// - Parameters:
    ///   - baseType: The fundamental data type
    ///   - isList: Whether the property contains a list of values
    ///   - isOptional: Whether the property value can be nil
    ///   - description: Optional description of the property
    public init(baseType: String, isList: Bool, isOptional: Bool, description: String? = nil) {
        self.baseType = baseType
        self.isList = isList
        self.isOptional = isOptional
        self.description = description
    }
}

