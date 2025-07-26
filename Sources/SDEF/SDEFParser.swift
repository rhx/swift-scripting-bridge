//
// SDEFParser.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// A parser that extracts structured data from SDEF XML documents.
///
/// The `SDEFParser` processes Apple Scripting Definition (.sdef) XML files and converts them
/// into structured Swift data models. It handles XML includes (such as CocoaStandard.sdef),
/// merges class extensions with their base classes, and provides comprehensive error handling
/// for malformed or incomplete SDEF files.
///
/// The parser automatically loads standard Apple scripting definitions when encountereding
/// XI:Include directives, ensuring that generated code includes all necessary base classes
/// and standard scripting functionality.
public final class SDEFParser {
    private let document: XMLDocument
    private let includeHidden: Bool
    private let verbose: Bool
    private var standardClasses: [String: SDEFClass] = [:]
    private var standardEnums: [String: SDEFEnumeration] = [:]

    /// Creates a new SDEF parser with the specified configuration.
    ///
    /// The parser processes the provided XML document and optionally includes hidden
    /// definitions that are marked as such in the SDEF file. Verbose mode provides
    /// detailed logging of the parsing process, which can be useful for debugging
    /// malformed or complex SDEF files.
    ///
    /// - Parameters:
    ///   - document: The XML document containing the SDEF content to parse
    ///   - includeHidden: Whether to include definitions marked as hidden
    ///   - verbose: Whether to enable detailed logging during parsing
    public init(document: XMLDocument, includeHidden: Bool, verbose: Bool) {
        self.document = document
        self.includeHidden = includeHidden
        self.verbose = verbose
    }

    /// Parses the SDEF document and returns a structured model.
    ///
    /// This method processes the entire SDEF document, including any XI:Include directives
    /// that reference external definition files such as CocoaStandard.sdef. It builds a
    /// complete model that merges class extensions with their base classes and includes
    /// all standard Apple scripting definitions.
    ///
    /// The parsing process involves multiple phases: first, external includes are processed
    /// to load standard definitions; then, the main document is parsed to extract suites,
    /// classes, and other definitions; finally, class extensions are merged with their
    /// corresponding base classes to create complete class definitions.
    ///
    /// - Returns: A complete SDEF model containing all parsed definitions
    /// - Throws: `SDEFParsingError` if the XML structure is invalid or required elements are missing
    public func parse() throws -> SDEFModel {
        guard let rootElement = document.rootElement() else {
            throw SDEFParsingError.invalidStructure("Invalid SDEF: no root element")
        }

        // First, process any XI includes to load standard definitions
        try processXIIncludes(from: rootElement)

        let suites = try parseSuites(from: rootElement)

        // Merge class extensions with standard classes
        let mergedSuites = try mergeClassExtensions(suites)

        return SDEFModel(suites: mergedSuites, standardClasses: Array(standardClasses.values))
    }
}

private extension SDEFParser {
    func processXIIncludes(from element: XMLElement) throws {
        // Look for xi:include elements with proper namespace handling
        do {
            let includeElements = try element.nodes(forXPath: ".//xi:include")

            for includeNode in includeElements {
                guard let includeElement = includeNode as? XMLElement,
                      let href = includeElement.attribute(forName: "href")?.stringValue else { continue }

                // Handle file:// URLs for CocoaStandard.sdef
                if href.contains("CocoaStandard.sdef") {
                    try loadCocoaStandardDefinitions()
                }
            }
        } catch {
            // If xi:include namespace processing fails, try without namespace prefix
            do {
                let includeElements = try element.nodes(forXPath: ".//include")

                for includeNode in includeElements {
                    guard let includeElement = includeNode as? XMLElement,
                          let href = includeElement.attribute(forName: "href")?.stringValue else { continue }

                    // Handle file:// URLs for CocoaStandard.sdef
                    if href.contains("CocoaStandard.sdef") {
                        try loadCocoaStandardDefinitions()
                    }
                }
            } catch {
                // If no includes found, continue without error as this is optional
                if verbose {
                    print("No XI:Include elements found, proceeding without standard definitions")
                }
            }
        }
    }

    func loadCocoaStandardDefinitions() throws {
        let cocoaStandardPath = "/System/Library/ScriptingDefinitions/CocoaStandard.sdef"
        guard FileManager.default.fileExists(atPath: cocoaStandardPath) else {
            if verbose {
                print("Warning: CocoaStandard.sdef not found, adding fallback standard definitions")
            }
            addFallbackStandardDefinitions()
            return
        }

        do {
            let cocoaData = try Data(contentsOf: URL(fileURLWithPath: cocoaStandardPath))
            let cocoaDocument = try XMLDocument(data: cocoaData, options: [])

            if let cocoaRoot = cocoaDocument.rootElement() {
                let cocoaSuites = try parseSuites(from: cocoaRoot)

                // Store standard classes and enums for later merging
                for suite in cocoaSuites {
                    for sdefClass in suite.classes {
                        standardClasses[sdefClass.name] = sdefClass
                    }
                    for enumeration in suite.enumerations {
                        standardEnums[enumeration.name] = enumeration
                    }
                }

                if verbose {
                    print("Loaded \(standardClasses.count) standard classes and \(standardEnums.count) standard enums")
                }
            }
        } catch {
            if verbose {
                print("Warning: Failed to load CocoaStandard.sdef: \(error), adding fallback definitions")
            }
            addFallbackStandardDefinitions()
        }
    }

    func addFallbackStandardDefinitions() {
        // Add minimal standard class definitions for common cases
        let windowClass = SDEFClass(
            name: "window",
            pluralName: "windows",
            code: "cwin",
            description: "A window.",
            inherits: nil,
            properties: [
                SDEFProperty(name: "name", code: "pnam", type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true), description: "The title of the window.", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "id", code: "ID  ", type: SDEFPropertyType(baseType: "integer", isList: false, isOptional: true), description: "The unique identifier of the window.", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "index", code: "pidx", type: SDEFPropertyType(baseType: "integer", isList: false, isOptional: true), description: "The index of the window, ordered front to back.", access: "", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "bounds", code: "pbnd", type: SDEFPropertyType(baseType: "rectangle", isList: false, isOptional: true), description: "The bounding rectangle of the window.", access: "", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "closeable", code: "hclb", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Does the window have a close button?", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "miniaturizable", code: "ismn", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Does the window have a minimize button?", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "miniaturized", code: "pmnd", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Is the window minimized right now?", access: "", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "resizable", code: "prsz", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Can the window be resized?", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "visible", code: "pvis", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Is the window visible right now?", access: "", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "zoomable", code: "iszm", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Does the window have a zoom button?", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "zoomed", code: "pzum", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Is the window zoomed right now?", access: "", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "document", code: "docu", type: SDEFPropertyType(baseType: "document", isList: false, isOptional: true), description: "The document whose contents are displayed in the window.", access: "r", cocoaKey: nil, isHidden: false)
            ],
            elements: [],
            respondsTo: ["close", "print", "save"],
            isHidden: false
        )

        let documentClass = SDEFClass(
            name: "document",
            pluralName: "documents",
            code: "docu",
            description: "A document.",
            inherits: nil,
            properties: [
                SDEFProperty(name: "name", code: "pnam", type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true), description: "Its name.", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "modified", code: "imod", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Has it been modified since the last save?", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "file", code: "file", type: SDEFPropertyType(baseType: "file", isList: false, isOptional: true), description: "Its location on disk, if it has one.", access: "r", cocoaKey: nil, isHidden: false)
            ],
            elements: [],
            respondsTo: ["close", "print", "save"],
            isHidden: false
        )

        let applicationClass = SDEFClass(
            name: "application",
            pluralName: "applications",
            code: "capp",
            description: "The application's top-level scripting object.",
            inherits: nil,
            properties: [
                SDEFProperty(name: "name", code: "pnam", type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true), description: "The name of the application.", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "frontmost", code: "pisf", type: SDEFPropertyType(baseType: "boolean", isList: false, isOptional: true), description: "Is this the active application?", access: "r", cocoaKey: nil, isHidden: false),
                SDEFProperty(name: "version", code: "vers", type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true), description: "The version number of the application.", access: "r", cocoaKey: nil, isHidden: false)
            ],
            elements: [
                SDEFElement(type: "document", cocoaKey: nil),
                SDEFElement(type: "window", cocoaKey: nil)
            ],
            respondsTo: ["open", "print", "quit"],
            isHidden: false
        )

        standardClasses["window"] = windowClass
        standardClasses["document"] = documentClass
        standardClasses["application"] = applicationClass

        // Add standard enums
        let saveOptionsEnum = SDEFEnumeration(
            name: "save options",
            code: "savo",
            description: "Save options for documents",
            enumerators: [
                SDEFEnumerator(name: "yes", code: "yes ", description: "Save the file.", stringValue: nil),
                SDEFEnumerator(name: "no", code: "no  ", description: "Do not save the file.", stringValue: nil),
                SDEFEnumerator(name: "ask", code: "ask ", description: "Ask the user whether or not to save the file.", stringValue: nil)
            ],
            isHidden: false
        )

        let printingErrorEnum = SDEFEnumeration(
            name: "printing error handling",
            code: "enum",
            description: "How to handle printing errors",
            enumerators: [
                SDEFEnumerator(name: "standard", code: "lwst", description: "Standard PostScript error handling", stringValue: nil),
                SDEFEnumerator(name: "detailed", code: "lwdt", description: "print a detailed report of PostScript errors", stringValue: nil)
            ],
            isHidden: false
        )

        standardEnums["save options"] = saveOptionsEnum
        standardEnums["printing error handling"] = printingErrorEnum

        if verbose {
            print("Added \(standardClasses.count) fallback standard classes and \(standardEnums.count) fallback standard enums")
        }
    }

    func parseSuites(from element: XMLElement) throws -> [SDEFSuite] {
        let suiteElements = try element.nodes(forXPath: ".//suite")
        var suites: [SDEFSuite] = []

        for suiteNode in suiteElements {
            guard let suiteElement = suiteNode as? XMLElement else { continue }

            let suite = try parseSuite(from: suiteElement)
            suites.append(suite)
        }

        return suites
    }

    func mergeClassExtensions(_ suites: [SDEFSuite]) throws -> [SDEFSuite] {
        var mergedSuites: [SDEFSuite] = []

        for suite in suites {
            var mergedClasses = suite.classes
            var allEnums = suite.enumerations

            // Add standard enums that aren't already present
            for (name, standardEnum) in standardEnums {
                if !allEnums.contains(where: { $0.name == name }) {
                    allEnums.append(standardEnum)
                }
            }

            // Process class extensions
            for classExtension in suite.classExtensions {
                let extendedClassName = classExtension.extends

                // Check if we have a standard class to extend
                if let standardClass = standardClasses[extendedClassName] {
                    // Create merged class with standard properties + extension properties
                    let mergedClass = SDEFClass(
                        name: standardClass.name,
                        pluralName: standardClass.pluralName,
                        code: standardClass.code,
                        description: standardClass.description,
                        inherits: standardClass.inherits,
                        properties: standardClass.properties + classExtension.properties,
                        elements: standardClass.elements + classExtension.elements,
                        respondsTo: standardClass.respondsTo + classExtension.respondsTo,
                        isHidden: standardClass.isHidden
                    )
                    mergedClasses.append(mergedClass)
                } else {
                    // Create a new class from the extension
                    let newClass = SDEFClass(
                        name: extendedClassName,
                        pluralName: nil,
                        code: "",
                        description: "Extended \(extendedClassName)",
                        inherits: nil,
                        properties: classExtension.properties,
                        elements: classExtension.elements,
                        respondsTo: classExtension.respondsTo,
                        isHidden: false
                    )
                    mergedClasses.append(newClass)
                }
            }

            let mergedSuite = SDEFSuite(
                name: suite.name,
                code: suite.code,
                description: suite.description,
                classes: mergedClasses,
                enumerations: allEnums,
                commands: suite.commands,
                classExtensions: [] // Clear extensions as they're now merged
            )

            mergedSuites.append(mergedSuite)
        }

        return mergedSuites
    }

    func parseSuite(from element: XMLElement) throws -> SDEFSuite {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue

        let classes = try parseClasses(from: element)
        let enumerations = try parseEnumerations(from: element)
        let commands = try parseCommands(from: element)
        let classExtensions = try parseClassExtensions(from: element)

        return SDEFSuite(
            name: name,
            code: code,
            description: description,
            classes: classes,
            enumerations: enumerations,
            commands: commands,
            classExtensions: classExtensions
        )
    }

    func parseClasses(from element: XMLElement) throws -> [SDEFClass] {
        let classElements = try element.nodes(forXPath: ".//class")
        var classes: [SDEFClass] = []

        for classNode in classElements {
            guard let classElement = classNode as? XMLElement else { continue }

            let isHidden = classElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let sdefClass = try parseClass(from: classElement)
            classes.append(sdefClass)
        }

        return classes
    }

    func parseClass(from element: XMLElement) throws -> SDEFClass {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let pluralName = element.attribute(forName: "plural")?.stringValue
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let inherits = element.attribute(forName: "inherits")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"

        let properties = try parseProperties(from: element)
        let elements = try parseElements(from: element)
        let respondsTo = try parseRespondsTo(from: element)

        return SDEFClass(
            name: name,
            pluralName: pluralName,
            code: code,
            description: description,
            inherits: inherits,
            properties: properties,
            elements: elements,
            respondsTo: respondsTo,
            isHidden: isHidden
        )
    }

    func parseClassExtensions(from element: XMLElement) throws -> [SDEFClassExtension] {
        let extensionElements = try element.nodes(forXPath: ".//class-extension")
        var extensions: [SDEFClassExtension] = []

        for extensionNode in extensionElements {
            guard let extensionElement = extensionNode as? XMLElement else { continue }

            let extends = extensionElement.attribute(forName: "extends")?.stringValue ?? ""
            let properties = try parseProperties(from: extensionElement)
            let elements = try parseElements(from: extensionElement)
            let respondsTo = try parseRespondsTo(from: extensionElement)

            let classExtension = SDEFClassExtension(
                extends: extends,
                properties: properties,
                elements: elements,
                respondsTo: respondsTo
            )

            extensions.append(classExtension)
        }

        return extensions
    }

    func parseProperties(from element: XMLElement) throws -> [SDEFProperty] {
        let propertyElements = try element.nodes(forXPath: ".//property")
        var properties: [SDEFProperty] = []

        for propertyNode in propertyElements {
            guard let propertyElement = propertyNode as? XMLElement else { continue }

            let isHidden = propertyElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let property = try parseProperty(from: propertyElement)
            properties.append(property)
        }

        return properties
    }

    func parseProperty(from element: XMLElement) throws -> SDEFProperty {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let access = element.attribute(forName: "access")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"

        let type = try parsePropertyType(from: element)

        // Look for cocoa key
        var cocoaKey: String?
        if let cocoaElements = try? element.nodes(forXPath: ".//cocoa"),
           let cocoaElement = cocoaElements.first as? XMLElement {
            cocoaKey = cocoaElement.attribute(forName: "key")?.stringValue
        }

        return SDEFProperty(
            name: name,
            code: code,
            type: type,
            description: description,
            access: access,
            cocoaKey: cocoaKey,
            isHidden: isHidden
        )
    }

    func parsePropertyType(from element: XMLElement) throws -> SDEFPropertyType {
        // Try to find type element first
        if let typeElements = try? element.nodes(forXPath: ".//type"),
           let typeElement = typeElements.first as? XMLElement {
            let baseType = typeElement.attribute(forName: "type")?.stringValue ?? "Any"
            let isList = typeElement.attribute(forName: "list")?.stringValue == "yes"
            return SDEFPropertyType(baseType: baseType, isList: isList, isOptional: true)
        }

        // Fallback to type attribute
        let typeAttr = element.attribute(forName: "type")?.stringValue ?? "Any"
        return SDEFPropertyType(baseType: typeAttr, isList: false, isOptional: true)
    }

    func parseElements(from element: XMLElement) throws -> [SDEFElement] {
        let elementElements = try element.nodes(forXPath: ".//element")
        var elements: [SDEFElement] = []

        for elementNode in elementElements {
            guard let elementElement = elementNode as? XMLElement else { continue }

            let type = elementElement.attribute(forName: "type")?.stringValue ?? ""
            let cocoaKey = elementElement.attribute(forName: "key")?.stringValue

            let elementObj = SDEFElement(type: type, cocoaKey: cocoaKey)
            elements.append(elementObj)
        }

        return elements
    }

    func parseRespondsTo(from element: XMLElement) throws -> [String] {
        let respondsToElements = try element.nodes(forXPath: ".//responds-to")
        var commands: [String] = []

        for respondsToNode in respondsToElements {
            guard let respondsToElement = respondsToNode as? XMLElement else { continue }

            if let command = respondsToElement.attribute(forName: "command")?.stringValue {
                commands.append(command)
            }
        }

        return commands
    }

    func parseEnumerations(from element: XMLElement) throws -> [SDEFEnumeration] {
        let enumElements = try element.nodes(forXPath: ".//enumeration")
        var enumerations: [SDEFEnumeration] = []

        for enumNode in enumElements {
            guard let enumElement = enumNode as? XMLElement else { continue }

            let isHidden = enumElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let enumeration = try parseEnumeration(from: enumElement)
            enumerations.append(enumeration)
        }

        return enumerations
    }

    func parseEnumeration(from element: XMLElement) throws -> SDEFEnumeration {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"

        let enumerators = try parseEnumerators(from: element)

        return SDEFEnumeration(
            name: name,
            code: code,
            description: description,
            enumerators: enumerators,
            isHidden: isHidden
        )
    }

    func parseEnumerators(from element: XMLElement) throws -> [SDEFEnumerator] {
        let enumeratorElements = try element.nodes(forXPath: ".//enumerator")
        var enumerators: [SDEFEnumerator] = []

        for enumeratorNode in enumeratorElements {
            guard let enumeratorElement = enumeratorNode as? XMLElement else { continue }

            let name = enumeratorElement.attribute(forName: "name")?.stringValue ?? ""
            let code = enumeratorElement.attribute(forName: "code")?.stringValue ?? ""
            let description = enumeratorElement.attribute(forName: "description")?.stringValue

            // Look for cocoa string-value
            var stringValue: String?
            if let cocoaElements = try? enumeratorElement.nodes(forXPath: ".//cocoa"),
               let cocoaElement = cocoaElements.first as? XMLElement {
                stringValue = cocoaElement.attribute(forName: "string-value")?.stringValue
            }

            let enumerator = SDEFEnumerator(
                name: name,
                code: code,
                description: description,
                stringValue: stringValue
            )

            enumerators.append(enumerator)
        }

        return enumerators
    }

    func parseCommands(from element: XMLElement) throws -> [SDEFCommand] {
        let commandElements = try element.nodes(forXPath: ".//command")
        var commands: [SDEFCommand] = []

        for commandNode in commandElements {
            guard let commandElement = commandNode as? XMLElement else { continue }

            let isHidden = commandElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let command = try parseCommand(from: commandElement)
            commands.append(command)
        }

        return commands
    }

    func parseCommand(from element: XMLElement) throws -> SDEFCommand {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"

        // Parse direct parameter
        var directParameter: SDEFParameter?
        if let directParamElements = try? element.nodes(forXPath: ".//direct-parameter"),
           let directParamElement = directParamElements.first as? XMLElement {
            directParameter = try parseParameter(from: directParamElement, name: nil)
        }

        // Parse parameters
        let parameterElements = try element.nodes(forXPath: ".//parameter")
        var parameters: [SDEFParameter] = []
        for paramNode in parameterElements {
            guard let paramElement = paramNode as? XMLElement else { continue }
            let paramName = paramElement.attribute(forName: "name")?.stringValue
            let parameter = try parseParameter(from: paramElement, name: paramName)
            parameters.append(parameter)
        }

        // Parse result type
        var result: SDEFPropertyType?
        if let resultElements = try? element.nodes(forXPath: ".//result"),
           let resultElement = resultElements.first as? XMLElement {
            result = try parsePropertyType(from: resultElement)
        }

        return SDEFCommand(
            name: name,
            code: code,
            description: description,
            directParameter: directParameter,
            parameters: parameters,
            result: result,
            isHidden: isHidden
        )
    }

    func parseParameter(from element: XMLElement, name: String?) throws -> SDEFParameter {
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let isOptional = element.attribute(forName: "optional")?.stringValue == "yes"

        let type = try parsePropertyType(from: element)

        return SDEFParameter(
            name: name,
            code: code,
            type: type,
            description: description,
            isOptional: isOptional
        )
    }
}

/// Errors that can occur during SDEF parsing.
///
/// These errors provide detailed information about problems encountered while parsing
/// SDEF XML documents, including structural issues, missing required elements, and
/// invalid data formats.
public enum SDEFParsingError: Error {
    /// The SDEF XML structure is invalid or malformed
    case invalidStructure(String)

    /// A required element or attribute is missing from the SDEF
    case missingRequiredElement(String)

    /// An XML processing error occurred
    case xmlError(Error)
}

extension SDEFParsingError: LocalizedError {
    /// A localised description of the parsing error.
    ///
    /// Provides human-readable error messages that can be displayed to users or
    /// logged for debugging purposes. The descriptions include specific details
    /// about what went wrong during the parsing process.
    ///
    /// - Returns: A user-friendly description of the error
    public var errorDescription: String? {
        switch self {
        case .invalidStructure(let message):
            return "Invalid SDEF structure: \(message)"
        case .missingRequiredElement(let element):
            return "Missing required SDEF element: \(element)"
        case .xmlError(let error):
            return "XML processing error: \(error.localizedDescription)"
        }
    }
}
