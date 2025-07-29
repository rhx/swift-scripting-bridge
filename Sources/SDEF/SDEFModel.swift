//
// SDEFModel.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Information about an included SDEF file that was processed during parsing.
///
/// When an SDEF file includes other definitions via xi:include directives, this structure
/// tracks the information needed to generate separate Swift files for the included content.
public struct SDEFInclude: Codable {
    /// The original href URL from the xi:include directive
    public let href: String
    /// The basename that should be used for the generated Swift file
    public let basename: String
    /// The model containing all definitions from the included file
    public let model: SDEFModel

    public init(href: String, basename: String, model: SDEFModel) {
        self.href = href
        self.basename = basename
        self.model = model
    }
}

/// A complete SDEF (Scripting Definition) model representing the structure of an Apple Scripting Definition file.
///
/// The `SDEFModel` serves as the root container for all scripting definitions parsed from an .sdef XML file.
/// It organises the scripting interface into logical suites, each containing classes, enumerations, and commands
/// that define how external applications can interact with a scriptable macOS application.
///
/// - Parameters:
///   - suites: The collection of scripting suites defined in the SDEF file
public struct SDEFModel: Codable {
    /// The scripting suites contained within this SDEF model
    public let suites: [SDEFSuite]
    /// The standard classes loaded from CocoaStandard.sdef
    public let standardClasses: [SDEFClass]
    /// Information about included SDEF files that were processed
    public let includes: [SDEFInclude]

    /// Creates a new SDEF model with the specified suites.
    ///
    /// - Parameters:
    ///   - suites: The scripting suites to include in this model
    ///   - standardClasses: The standard classes from CocoaStandard.sdef
    ///   - includes: Information about included SDEF files that were processed
    public init(suites: [SDEFSuite], standardClasses: [SDEFClass] = [], includes: [SDEFInclude] = []) {
        self.suites = suites
        self.standardClasses = standardClasses
        self.includes = includes
    }
}

/// A scripting suite that groups related classes, enumerations, and commands together.
///
/// In Apple's scripting architecture, suites provide logical groupings for related functionality.
/// For example, a "Text Suite" might contain classes for documents, paragraphs, and words,
/// along with commands for text manipulation. Each suite has a unique four-character code
/// that identifies it in the Apple Event system.
///
/// - Parameters:
///   - name: The human-readable name of the suite
///   - code: The four-character Apple Event code identifying this suite
///   - description: An optional detailed description of the suite's purpose
///   - classes: The scriptable classes defined within this suite
///   - enumerations: The enumeration types defined within this suite
///   - commands: The scriptable commands available within this suite
///   - classExtensions: Extensions to existing classes from other suites
public struct SDEFSuite: Codable {
    /// The human-readable name of this scripting suite
    public let name: String

    /// The four-character Apple Event code that uniquely identifies this suite
    public let code: String

    /// An optional description explaining the purpose and functionality of this suite
    public let description: String?

    /// The scriptable classes defined within this suite
    public let classes: [SDEFClass]

    /// The enumeration types available within this suite
    public let enumerations: [SDEFEnumeration]

    /// The scriptable commands that can be executed within this suite
    public let commands: [SDEFCommand]

    /// Extensions to classes defined in other suites, adding suite-specific functionality
    public let classExtensions: [SDEFClassExtension]

    /// Creates a new scripting suite with the specified components.
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

/// A scriptable class that represents an object type within the application's object model.
///
/// SDEF classes define the structure and behaviour of objects that can be manipulated through
/// Apple Events scripting. Each class has properties that can be read or modified, elements
/// that represent collections of child objects, and may respond to specific commands.
/// Classes can inherit from other classes, forming an inheritance hierarchy.
///
/// - Parameters:
///   - name: The singular name of the class
///   - pluralName: The plural form used when referring to collections
///   - code: The four-character Apple Event code for this class
///   - description: Optional description of the class's purpose
///   - inherits: The name of the parent class, if any
///   - properties: The properties that instances of this class possess
///   - elements: The types of child objects this class can contain
///   - respondsTo: The commands this class can respond to
///   - isHidden: Whether this class is marked as hidden in the scripting interface
public struct SDEFClass: Codable {
    /// The singular name of this class
    public let name: String

    /// The plural form used when referring to collections of this class
    public let pluralName: String?

    /// The four-character Apple Event code that identifies this class
    public let code: String

    /// An optional description of what this class represents
    public let description: String?

    /// The name of the parent class from which this class inherits, if any
    public let inherits: String?

    /// The properties that instances of this class possess
    public let properties: [SDEFProperty]

    /// The types of child objects that this class can contain
    public let elements: [SDEFElement]

    /// The names of commands that this class can respond to
    public let respondsTo: [String]

    /// Whether this class is marked as hidden in the scripting interface
    public let isHidden: Bool

    /// Creates a new SDEF class with the specified attributes.
    ///
    /// - Parameters:
    ///   - name: The singular name of the class
    ///   - pluralName: The plural form for collections, or nil if not specified
    ///   - code: The four-character Apple Event code
    ///   - description: Optional description of the class
    ///   - inherits: Name of the parent class, or nil if no inheritance
    ///   - properties: Properties that instances possess
    ///   - elements: Types of child objects this class can contain
    ///   - respondsTo: Names of commands this class responds to
    ///   - isHidden: Whether the class is hidden from normal scripting use
    public init(name: String, pluralName: String?, code: String, description: String?, inherits: String?, properties: [SDEFProperty], elements: [SDEFElement], respondsTo: [String], isHidden: Bool) {
        self.name = name
        self.pluralName = pluralName
        self.code = code
        self.description = description
        self.inherits = inherits
        self.properties = properties
        self.elements = elements
        self.respondsTo = respondsTo
        self.isHidden = isHidden
    }
}

/// An extension to an existing class that adds additional properties and functionality.
///
/// Class extensions allow suites to add suite-specific properties and behaviour to classes
/// defined in other suites. This enables modular design where base classes can be extended
/// with specialised functionality without modifying the original class definition.
///
/// - Parameters:
///   - extends: The name of the class being extended
///   - properties: Additional properties added by this extension
///   - elements: Additional element types added by this extension
///   - respondsTo: Additional commands the extended class responds to
public struct SDEFClassExtension: Codable {
    /// The name of the class being extended
    public let extends: String

    /// Additional properties added to the extended class
    public let properties: [SDEFProperty]

    /// Additional element types that the extended class can contain
    public let elements: [SDEFElement]

    /// Additional commands that the extended class can respond to
    public let respondsTo: [String]

    /// Creates a new class extension with the specified additions.
    ///
    /// - Parameters:
    ///   - extends: The name of the class being extended
    ///   - properties: Additional properties to add
    ///   - elements: Additional element types to add
    ///   - respondsTo: Additional commands the class should respond to
    public init(extends: String, properties: [SDEFProperty], elements: [SDEFElement], respondsTo: [String]) {
        self.extends = extends
        self.properties = properties
        self.elements = elements
        self.respondsTo = respondsTo
    }
}

/// A property of a scriptable class that can be read or modified through scripting.
///
/// Properties represent the attributes of scriptable objects that can be accessed and
/// potentially modified through Apple Events. Each property has a specific type and
/// access permissions that determine how scripts can interact with it. Properties
/// may be read-only, write-only, or read-write depending on their access specification.
///
/// - Parameters:
///   - name: The human-readable name of the property
///   - code: The four-character Apple Event code for this property
///   - type: The data type and constraints for this property
///   - description: Optional description of the property's purpose
///   - access: The access permissions (read, write, or both)
///   - cocoaKey: The Cocoa key name for this property, used for better Swift naming
///   - isHidden: Whether this property is hidden from normal scripting use
public struct SDEFProperty: Codable {
    /// The human-readable name of this property
    public let name: String

    /// The four-character Apple Event code that identifies this property
    public let code: String

    /// The data type and constraints for this property's value
    public let type: SDEFPropertyType

    /// An optional description of what this property represents
    public let description: String?

    /// The access permissions for this property (read, write, or both)
    public let access: String?

    /// The Cocoa key name for this property, used for generating better Swift property names
    public let cocoaKey: String?

    /// Whether this property is marked as hidden in the scripting interface
    public let isHidden: Bool

    /// Creates a new property with the specified attributes.
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
/// Elements represent the types of child objects that can be contained within a parent object.
/// For example, a document might contain paragraph elements, or an application might contain
/// window elements. Elements define the hierarchical structure of the application's object model.
///
/// - Parameters:
///   - type: The name of the class type that can be contained
///   - cocoaKey: The Cocoa key path used to access these elements
public struct SDEFElement: Codable {
    /// The name of the class type that can be contained as an element
    public let type: String

    /// The Cocoa key path used to access this collection of elements
    public let cocoaKey: String?

    /// Creates a new element specification.
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
/// Property types define the expected data format for property values, including the base
/// type (such as text, integer, or a custom class), whether the property contains a
/// single value or a list of values, and whether the property value is optional.
///
/// - Parameters:
///   - baseType: The fundamental data type (text, integer, class name, etc.)
///   - isList: Whether this property contains a list of values
///   - isOptional: Whether this property's value can be nil
public struct SDEFPropertyType: Codable {
    /// The fundamental data type for this property
    public let baseType: String

    /// Whether this property contains a list of values rather than a single value
    public let isList: Bool

    /// Whether this property's value can be nil
    public let isOptional: Bool

    /// Optional description of what this property represents
    public let description: String?

    /// Creates a new property type specification.
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

/// An enumeration type that defines a set of named constant values.
///
/// SDEF enumerations define sets of predefined constant values that can be used as
/// property values or command parameters. Each enumeration has a collection of
/// enumerators, where each enumerator represents a specific constant value with
/// its own four-character Apple Event code.
///
/// - Parameters:
///   - name: The name of the enumeration type
///   - code: The four-character Apple Event code for this enumeration
///   - description: Optional description of the enumeration's purpose
///   - enumerators: The constant values defined within this enumeration
///   - isHidden: Whether this enumeration is hidden from normal scripting use
public struct SDEFEnumeration: Codable {
    /// The name of this enumeration type
    public let name: String

    /// The four-character Apple Event code that identifies this enumeration
    public let code: String

    /// An optional description of what this enumeration represents
    public let description: String?

    /// The constant values defined within this enumeration
    public let enumerators: [SDEFEnumerator]

    /// Whether this enumeration is marked as hidden in the scripting interface
    public let isHidden: Bool

    /// Creates a new enumeration with the specified enumerators.
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
/// Enumerators represent the individual named constants within an enumeration type.
/// Each enumerator has its own four-character Apple Event code and may include
/// additional metadata such as a string value for Cocoa binding purposes.
///
/// - Parameters:
///   - name: The name of this constant value
///   - code: The four-character Apple Event code for this enumerator
///   - description: Optional description of what this constant represents
///   - stringValue: Optional string value used for Cocoa bindings
public struct SDEFEnumerator: Codable {
    /// The name of this constant value
    public let name: String

    /// The four-character Apple Event code that identifies this enumerator
    public let code: String

    /// An optional description of what this constant represents
    public let description: String?

    /// An optional string value used for Cocoa binding purposes
    public let stringValue: String?

    /// Creates a new enumerator with the specified attributes.
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

/// A scriptable command that can be executed on objects within the application.
///
/// Commands represent actions that can be performed through Apple Events scripting.
/// Each command may take parameters and return a result. Commands can be sent to
/// specific objects or to the application as a whole, depending on their definition
/// and the target object's capabilities.
///
/// - Parameters:
///   - name: The human-readable name of the command
///   - code: The four-character Apple Event code for this command
///   - description: Optional description of what the command does
///   - directParameter: The main parameter passed directly to the command
///   - parameters: Additional named parameters for the command
///   - result: The type of value returned by the command
///   - isHidden: Whether this command is hidden from normal scripting use
public struct SDEFCommand: Codable {
    /// The human-readable name of this command
    public let name: String

    /// The four-character Apple Event code that identifies this command
    public let code: String

    /// An optional description of what this command does
    public let description: String?

    /// The main parameter passed directly to the command, if any
    public let directParameter: SDEFParameter?

    /// Additional named parameters that the command accepts
    public let parameters: [SDEFParameter]

    /// The type of value returned by executing this command
    public let result: SDEFPropertyType?

    /// Whether this command is marked as hidden in the scripting interface
    public let isHidden: Bool

    /// Creates a new command with the specified signature.
    ///
    /// - Parameters:
    ///   - name: The human-readable name of the command
    ///   - code: The four-character Apple Event code
    ///   - description: Optional description of the command's function
    ///   - directParameter: The main parameter, or nil if none
    ///   - parameters: Additional named parameters
    ///   - result: The return type, or nil if the command returns nothing
    ///   - isHidden: Whether the command is hidden from normal use
    public init(name: String, code: String, description: String?, directParameter: SDEFParameter?, parameters: [SDEFParameter], result: SDEFPropertyType?, isHidden: Bool) {
        self.name = name
        self.code = code
        self.description = description
        self.directParameter = directParameter
        self.parameters = parameters
        self.result = result
        self.isHidden = isHidden
    }
}

/// A parameter that can be passed to a scriptable command.
///
/// Parameters define the inputs that commands accept, including both the direct
/// parameter (the main object the command acts upon) and additional named parameters
/// that modify the command's behaviour. Each parameter has a specific type and
/// may be marked as optional.
///
/// - Parameters:
///   - name: The name of the parameter, if it's a named parameter
///   - code: The four-character Apple Event code for this parameter
///   - type: The data type expected for this parameter
///   - description: Optional description of the parameter's purpose
///   - isOptional: Whether this parameter must be provided
public struct SDEFParameter: Codable {
    /// The name of this parameter, or nil for direct parameters
    public let name: String?

    /// The four-character Apple Event code that identifies this parameter
    public let code: String

    /// The data type expected for this parameter's value
    public let type: SDEFPropertyType

    /// An optional description of what this parameter is used for
    public let description: String?

    /// Whether this parameter is optional and may be omitted
    public let isOptional: Bool

    /// Creates a new parameter with the specified characteristics.
    ///
    /// - Parameters:
    ///   - name: The parameter name, or nil for direct parameters
    ///   - code: The four-character Apple Event code
    ///   - type: The expected data type for the parameter
    ///   - description: Optional description of the parameter
    ///   - isOptional: Whether the parameter may be omitted
    public init(name: String?, code: String, type: SDEFPropertyType, description: String?, isOptional: Bool) {
        self.name = name
        self.code = code
        self.type = type
        self.description = description
        self.isOptional = isOptional
    }
}
