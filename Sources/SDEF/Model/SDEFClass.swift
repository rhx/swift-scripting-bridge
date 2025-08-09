//
// SDEFClass.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// A scriptable class that represents an object type within the application's object model.
///
/// SDEF classes define the structure and behaviour of objects that can be manipulated through
/// Apple Events scripting. Each class represents a distinct type of object in the application's
/// domain, such as a document, window, or application-specific entity. Classes encapsulate both
/// data (through properties) and behaviour (through command responses), providing a complete
/// object model for scripting interactions.
///
/// The class definition includes properties that can be read or modified, elements that represent
/// collections of child objects, and command associations that specify which operations the class
/// supports. Classes can inherit from other classes, forming an inheritance hierarchy that enables
/// code reuse and maintains consistent behaviour across related object types.
///
/// Each class has a four-character Apple Event code that uniquely identifies it in the scripting
/// system, enabling precise object type resolution and command routing. The class may also specify
/// whether it should be hidden from normal scripting use, which is useful for internal or
/// deprecated object types.
public struct SDEFClass: Codable, Sendable {
    /// The singular name of this class.
    ///
    /// This name is used in scripting dictionaries and code generation
    /// to identify individual instances of the class. It should be
    /// descriptive and follow standard naming conventions.
    public let name: String

    /// The plural form used when referring to collections of this class.
    ///
    /// This name is used when accessing collections of objects of this type,
    /// such as "documents" for a collection of "document" objects.
    /// If not specified, a standard pluralisation will be applied.
    public let pluralName: String?

    /// The four-character Apple Event code that identifies this class.
    ///
    /// This unique identifier is used by the Apple Event system to identify
    /// object types in scripting commands. The code must be exactly four
    /// characters and should be registered to avoid conflicts.
    public let code: String

    /// An optional description of what this class represents.
    ///
    /// This description appears in scripting dictionaries and helps users
    /// understand the purpose and capabilities of objects of this type.
    /// It should clearly explain what the class represents in the application's domain.
    public let description: String?

    /// The name of the parent class from which this class inherits, if any.
    ///
    /// Inheritance allows this class to automatically gain all properties,
    /// elements, and command responses from its parent class. This enables
    /// hierarchical organisation of the object model and promotes code reuse.
    public let inherits: String?

    /// The properties that instances of this class possess.
    ///
    /// Properties define the attributes that can be accessed and potentially
    /// modified on objects of this class. Each property has a name, type,
    /// and access characteristics (read-only, read-write, etc.).
    public let properties: [SDEFProperty]

    /// The types of child objects that this class can contain.
    ///
    /// Elements define the types of objects that can be accessed as collections
    /// within instances of this class. For example, a document might contain
    /// paragraphs, and an application might contain documents.
    public let elements: [SDEFElement]

    /// The names of commands that this class can respond to.
    ///
    /// This list specifies which commands can be sent to objects of this class.
    /// It enables the scripting system to validate command compatibility and
    /// route commands to appropriate handlers.
    public let respondsTo: [String]

    /// Whether this class is marked as hidden in the scripting interface.
    ///
    /// Hidden classes are not exposed in the application's scripting dictionary
    /// and cannot be accessed through normal scripting mechanisms. This is
    /// typically used for internal or deprecated object types.
    public let isHidden: Bool

    /// Creates a new SDEF class with the specified attributes.
    ///
    /// This initialiser constructs a complete class definition that encapsulates all
    /// aspects of a scriptable object type. The class serves as a template for objects
    /// that can be created, accessed, and manipulated through the scripting interface.
    /// The four-character code must be unique within the application's scripting definition
    /// and should follow Apple's conventions for class codes.
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
/// defined in other suites without modifying the original class definition. This mechanism
/// supports modular design where different functional areas can augment base classes with
/// their own specialised capabilities while maintaining clean separation of concerns.
///
/// Extensions are particularly useful when an application wants to add domain-specific
/// functionality to standard classes like documents or windows. For example, a text editor
/// might extend the standard document class with text-specific properties like character
/// count or formatting options. The extension mechanism ensures that these additions don't
/// interfere with the base class definition and can coexist with extensions from other suites.
public struct SDEFClassExtension: Codable, Sendable {
    /// The name of the class being extended.
    ///
    /// This must match the name of an existing class defined in the same
    /// SDEF or in an imported definition. The extension will add its
    /// properties and elements to the named class.
    public let extends: String

    /// Additional properties added to the extended class.
    ///
    /// These properties will be available on all instances of the extended
    /// class, appearing alongside the original properties defined in the
    /// base class. Property names must not conflict with existing properties.
    public let properties: [SDEFProperty]

    /// Additional element types that the extended class can contain.
    ///
    /// These elements define new types of child objects that can be accessed
    /// as collections within instances of the extended class. Element types
    /// are additive and supplement those defined in the base class.
    public let elements: [SDEFElement]

    /// Additional commands that the extended class can respond to.
    ///
    /// This list specifies additional commands that can be sent to objects
    /// of the extended class, beyond those already supported by the base class.
    /// This enables suite-specific operations on extended objects.
    public let respondsTo: [String]

    /// Creates a new class extension with the specified additions.
    ///
    /// This initialiser constructs an extension that augments an existing class with
    /// additional capabilities. The extension mechanism allows different suites to
    /// contribute functionality to shared classes without creating conflicts or
    /// requiring modifications to the base class definition. All additions are
    /// purely additive and should complement rather than override base functionality.
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
