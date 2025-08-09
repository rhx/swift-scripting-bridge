//
// SDEFCommand.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// A scriptable command that can be executed on objects within the application.
///
/// Commands represent actions that can be performed through Apple Events scripting,
/// providing the primary mechanism for external scripts to invoke application functionality.
/// Each command defines a complete interface specification including parameters, return types,
/// and routing information that determines how the command is executed within the application.
///
/// Commands can be targeted at specific objects or at the application as a whole, depending
/// on their definition and the capabilities of the receiving object. The command structure
/// includes both a direct parameter (the primary object or value the command acts upon) and
/// optional named parameters that modify the command's behaviour or provide additional data.
/// This flexible parameter system enables commands to handle complex operations while maintaining
/// clear and consistent interfaces for script authors.
public struct SDEFCommand: Codable, Sendable {
    /// The human-readable name of this command.
    ///
    /// This name is used in scripting dictionaries and code generation to
    /// identify the command. It should be a clear, descriptive verb or verb
    /// phrase that indicates what action the command performs.
    public let name: String

    /// The four-character Apple Event code that identifies this command.
    ///
    /// This unique identifier is used by the Apple Event system to route
    /// command invocations to the appropriate handler. The code must be
    /// exactly four characters and should be registered to avoid conflicts.
    public let code: String

    /// An optional description of what this command does.
    ///
    /// This description appears in scripting dictionaries and helps users
    /// understand the command's purpose, behaviour, and appropriate usage
    /// scenarios. It should clearly explain the action performed and any side effects.
    public let description: String?

    /// The main parameter passed directly to the command, if any.
    ///
    /// The direct parameter represents the primary object or value that the
    /// command acts upon. Not all commands require a direct parameter,
    /// depending on their specific functionality and design.
    public let directParameter: SDEFParameter?

    /// Additional named parameters that the command accepts.
    ///
    /// These parameters provide additional data or modify the command's
    /// behaviour. Each parameter has a name and type specification,
    /// and may be marked as optional or required.
    public let parameters: [SDEFParameter]

    /// The type of value returned by executing this command.
    ///
    /// This specification defines what type of data the command produces
    /// as its result. If nil, the command performs its action but does
    /// not return a meaningful value to the caller.
    public let result: SDEFPropertyType?

    /// Whether this command is marked as hidden in the scripting interface.
    ///
    /// Hidden commands are not exposed in the application's scripting dictionary
    /// and cannot be invoked through normal scripting mechanisms. This is typically
    /// used for internal or deprecated commands.
    public let isHidden: Bool

    /// Creates a new command with the specified signature.
    ///
    /// This initialiser constructs a complete command definition that encapsulates all
    /// aspects of a scriptable action. The command serves as a contract between the
    /// scripting interface and the application's internal functionality, defining exactly
    /// what inputs are expected and what outputs will be produced. The four-character
    /// code must be unique within the application's command space.
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
/// Parameters define the inputs that commands accept, providing complete type and
/// constraint information for each piece of data that can be passed to a command.
/// The parameter system supports both direct parameters (the primary object or value
/// the command acts upon) and named parameters (additional data that modifies the
/// command's behaviour or provides supplementary information).
///
/// Each parameter includes type information that enables compile-time validation and
/// runtime type checking, ensuring that scripts provide appropriate data types and
/// that the command receives well-formed inputs. Parameters may be marked as optional,
/// allowing commands to have flexible interfaces that can accommodate different usage
/// patterns while maintaining type safety.
public struct SDEFParameter: Codable, Sendable {
    /// The name of this parameter, or nil for direct parameters.
    ///
    /// Named parameters use this identifier in command invocations,
    /// while direct parameters are passed without an explicit name.
    /// The name should be descriptive and follow standard conventions.
    public let name: String?

    /// The four-character Apple Event code that identifies this parameter.
    ///
    /// This unique code is used by the Apple Event system to identify
    /// the parameter in command messages. The code must be exactly four
    /// characters and should be unique within the command's parameter set.
    public let code: String

    /// The data type expected for this parameter's value.
    ///
    /// This specification defines what kind of data the parameter accepts,
    /// including the base type, collection semantics, and nullability constraints.
    /// It enables type checking and appropriate code generation.
    public let type: SDEFPropertyType

    /// An optional description of what this parameter is used for.
    ///
    /// This description appears in scripting dictionaries and helps users
    /// understand the parameter's purpose and how it affects the command's
    /// behaviour. It should explain the parameter's role and any constraints.
    public let description: String?

    /// Whether this parameter is optional and may be omitted.
    ///
    /// Optional parameters can be omitted from command invocations,
    /// allowing the command to use default behaviour or values.
    /// Required parameters must always be provided.
    public let isOptional: Bool

    /// Creates a new parameter with the specified characteristics.
    ///
    /// This initialiser constructs a complete parameter definition that specifies
    /// all aspects of a command input. The parameter serves as a contract between
    /// the script author and the command implementation, defining exactly what data
    /// is expected and how it should be provided. The type specification enables
    /// both compile-time validation and runtime type checking.
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

public extension SDEFCommand {
    /// The Objective-C selector string for this command.
    ///
    /// Builds the selector by converting the command name to a Swift method name
    /// and appending colons for each parameter. The selector format follows
    /// Objective-C conventions where each parameter adds a colon to the selector.
    var objcSelector: String {
        var selector = name.swiftMethodName

        // Add parameter labels for the selector
        if directParameter != nil {
            selector += ":"
        }

        for param in parameters {
            if let paramName = param.name?.objcParameterName {
                selector += paramName + ":"
            }
        }

        return selector
    }

    /// The Swift method name for this command.
    var swiftMethodName: String {
        name.swiftMethodName
    }
}

public extension SDEFParameter {
    /// The Objective-C parameter name for this parameter.
    var objcParameterName: String? {
        name?.objcParameterName
    }

    /// The Swift parameter name for this parameter.
    var swiftParameterName: String? {
        name?.swiftParameterName
    }
}
