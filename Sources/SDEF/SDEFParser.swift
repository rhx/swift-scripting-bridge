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
    private let debug: Bool
    private let trackIncludes: Bool
    private var standardClasses: [String: SDEFClass] = [:]
    private var standardEnums: [String: SDEFEnumeration] = [:]
    private var processedIncludes: [SDEFInclude] = []

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
    ///   - trackIncludes: Whether to track included SDEF files for recursive generation
    ///   - verbose: Whether to enable detailed logging during parsing
    ///   - debug: Whether to enable debug output during parsing
    public init(document: XMLDocument, includeHidden: Bool, trackIncludes: Bool = false, verbose: Bool, debug: Bool = false) {
        self.document = document
        self.includeHidden = includeHidden
        self.trackIncludes = trackIncludes
        self.verbose = verbose
        self.debug = debug
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

        // Ensure we have standard definitions even if there are no XI:Include elements
        // Only add fallback definitions if this looks like a real application SDEF
        if standardClasses.isEmpty {
            let looksLikeApplicationSDEF = suites.contains { suite in
                suite.classes.contains { $0.name.lowercased() == "application" } ||
                suite.classExtensions.contains { $0.extends.lowercased() == "application" }
            }

            if looksLikeApplicationSDEF {
                if debug {
                    print("DEBUG: No standard classes loaded but found application-related content, adding fallback definitions")
                }
                addFallbackStandardDefinitions()
            }
        }

        if debug {
            print("DEBUG: About to call mergeClassExtensions")
        }

        // Merge class extensions with standard classes
        let mergedSuites = try mergeClassExtensions(suites)

        if debug {
            print("DEBUG: mergeClassExtensions completed")
        }

        return SDEFModel(suites: mergedSuites, standardClasses: Array(standardClasses.values), includes: processedIncludes)
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

                // If tracking includes, create a model for CocoaStandard
                if trackIncludes {
                    let cocoaModel = SDEFModel(suites: cocoaSuites, standardClasses: [], includes: [])
                    let cocoaInclude = SDEFInclude(
                        href: "file://localhost/System/Library/ScriptingDefinitions/CocoaStandard.sdef",
                        basename: "CocoaStandard",
                        model: cocoaModel
                    )
                    processedIncludes.append(cocoaInclude)
                }

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

        if debug {
            print("DEBUG: mergeClassExtensions called with \(suites.count) suites")
            for suite in suites {
                print("DEBUG: Suite '\(suite.name)' has \(suite.classes.count) classes")
                for sdefClass in suite.classes {
                    print("DEBUG:   Class: '\(sdefClass.name)'")
                }
            }
        }

        for suite in suites {
            var mergedClasses = suite.classes
            var allEnums = suite.enumerations
            var mergedWithStandardClasses: Set<String> = []

            // Add standard enums that aren't already present
            for (name, standardEnum) in standardEnums {
                if !allEnums.contains(where: { $0.name == name }) {
                    allEnums.append(standardEnum)
                }
            }

            // Skip Standard Suite application class if a suite-specific application class exists
            // This prevents duplicate Application protocols
            if suite.name == "Standard Suite" {
                let hasApplicationClassInLaterSuite = suites.contains { otherSuite in
                    otherSuite.name != "Standard Suite" &&
                    otherSuite.classes.contains { $0.name == "application" }
                }

                if hasApplicationClassInLaterSuite {
                    if debug {
                        print("DEBUG: Removing 'application' class from Standard Suite as it will be overridden by suite-specific class")
                    }
                    mergedClasses = mergedClasses.filter { $0.name != "application" }
                }
            }

            // Merge suite-specific classes with standard classes (inheritance)
            for i in 0..<mergedClasses.count {
                let sdefClass = mergedClasses[i]

                // If this class exists in standard classes, merge them (inheritance)
                if let standardClass = standardClasses[sdefClass.name] {
                    if debug {
                        print("DEBUG: Merging suite class '\(sdefClass.name)' with standard class")
                        print("DEBUG: Standard class has \(standardClass.elements.count) elements, \(standardClass.properties.count) properties")
                        print("DEBUG: Suite class has \(sdefClass.elements.count) elements, \(sdefClass.properties.count) properties")
                    }

                    // Deduplicate properties and elements by name
                    var mergedProperties = standardClass.properties
                    let existingPropertyNames = Set(standardClass.properties.map { $0.name })
                    for suiteProperty in sdefClass.properties {
                        if !existingPropertyNames.contains(suiteProperty.name) {
                            mergedProperties.append(suiteProperty)
                        }
                    }

                    var mergedElements = standardClass.elements
                    let existingElementTypes = Set(standardClass.elements.map { $0.type })
                    for suiteElement in sdefClass.elements {
                        if !existingElementTypes.contains(suiteElement.type) {
                            mergedElements.append(suiteElement)
                        }
                    }

                    let mergedClass = SDEFClass(
                        name: sdefClass.name,
                        pluralName: sdefClass.pluralName ?? standardClass.pluralName,
                        code: sdefClass.code.isEmpty ? standardClass.code : sdefClass.code,
                        description: sdefClass.description ?? standardClass.description,
                        inherits: sdefClass.inherits ?? standardClass.inherits,
                        properties: mergedProperties,
                        elements: mergedElements,
                        respondsTo: standardClass.respondsTo + sdefClass.respondsTo,
                        isHidden: sdefClass.isHidden
                    )

                    if debug {
                        print("DEBUG: Merged class has \(mergedClass.elements.count) elements, \(mergedClass.properties.count) properties")
                    }

                    mergedClasses[i] = mergedClass
                    mergedWithStandardClasses.insert(sdefClass.name)
                }
            }

            // Process class extensions
            if debug && !suite.classExtensions.isEmpty {
                print("DEBUG: Processing \(suite.classExtensions.count) class extensions for suite '\(suite.name)'")
            }
            for classExtension in suite.classExtensions {
                let extendedClassName = classExtension.extends
                if debug {
                    print("DEBUG: Processing class extension extending '\(extendedClassName)' in suite '\(suite.name)'")
                }

                // First check if we're extending a class already in this suite
                if let existingClassIndex = mergedClasses.firstIndex(where: { $0.name.lowercased() == extendedClassName.lowercased() }) {
                    // Merge with existing class in this suite
                    let existingClass = mergedClasses[existingClassIndex]
                    if debug {
                        print("DEBUG: Merging class extension for '\(extendedClassName)' with existing class '\(existingClass.name)'")
                        print("DEBUG: Existing class has \(existingClass.elements.count) elements, \(existingClass.properties.count) properties")
                        print("DEBUG: Extension adds \(classExtension.elements.count) elements, \(classExtension.properties.count) properties")
                    }
                    // Deduplicate properties and elements by name
                    var mergedProperties = existingClass.properties
                    let existingPropertyNames = Set(existingClass.properties.map { $0.name })
                    for extensionProperty in classExtension.properties {
                        if !existingPropertyNames.contains(extensionProperty.name) {
                            mergedProperties.append(extensionProperty)
                        }
                    }

                    var mergedElements = existingClass.elements
                    let existingElementTypes = Set(existingClass.elements.map { $0.type })
                    for extensionElement in classExtension.elements {
                        if !existingElementTypes.contains(extensionElement.type) {
                            mergedElements.append(extensionElement)
                        }
                    }

                    let mergedClass = SDEFClass(
                        name: existingClass.name,
                        pluralName: existingClass.pluralName,
                        code: existingClass.code,
                        description: existingClass.description ?? classExtension.properties.first?.description,
                        inherits: existingClass.inherits,
                        properties: mergedProperties,
                        elements: mergedElements,
                        respondsTo: existingClass.respondsTo + classExtension.respondsTo,
                        isHidden: existingClass.isHidden
                    )
                    if debug {
                        print("DEBUG: Merged class has \(mergedClass.elements.count) elements, \(mergedClass.properties.count) properties")
                    }
                    mergedClasses[existingClassIndex] = mergedClass
                } else if let standardClass = standardClasses[extendedClassName] {
                    // Check if we have a standard class to extend
                    // Create merged class with standard properties + extension properties
                    if debug {
                        print("DEBUG: Creating extended class for '\(extendedClassName)' from standard class")
                        print("DEBUG: Standard class has \(standardClass.elements.count) elements, \(standardClass.properties.count) properties")
                        print("DEBUG: Extension adds \(classExtension.elements.count) elements, \(classExtension.properties.count) properties")
                    }
                    // Deduplicate properties and elements by name
                    var mergedProperties = standardClass.properties
                    let existingPropertyNames = Set(standardClass.properties.map { $0.name })
                    for extensionProperty in classExtension.properties {
                        if !existingPropertyNames.contains(extensionProperty.name) {
                            mergedProperties.append(extensionProperty)
                        }
                    }

                    var mergedElements = standardClass.elements
                    let existingElementTypes = Set(standardClass.elements.map { $0.type })
                    for extensionElement in classExtension.elements {
                        if !existingElementTypes.contains(extensionElement.type) {
                            mergedElements.append(extensionElement)
                        }
                    }

                    let mergedClass = SDEFClass(
                        name: standardClass.name,
                        pluralName: standardClass.pluralName,
                        code: standardClass.code,
                        description: standardClass.description,
                        inherits: standardClass.inherits,
                        properties: mergedProperties,
                        elements: mergedElements,
                        respondsTo: standardClass.respondsTo + classExtension.respondsTo,
                        isHidden: standardClass.isHidden
                    )
                    if debug {
                        print("DEBUG: Extended class has \(mergedClass.elements.count) elements, \(mergedClass.properties.count) properties")
                    }
                    mergedClasses.append(mergedClass)
                    mergedWithStandardClasses.insert(extendedClassName)
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

            // Track which classes were extended by class-extensions in this suite
            var classesExtendedByExtensions: Set<String> = []
            for classExtension in suite.classExtensions {
                classesExtendedByExtensions.insert(classExtension.extends)
            }

            // Add remaining standard classes that weren't merged with suite-specific classes
            // and weren't extended by class-extensions in any suite
            if debug {
                print("DEBUG: Processing standard classes for suite '\(suite.name)' (\(standardClasses.count) standard classes available)")
            }
            for (name, standardClass) in standardClasses {
                let wasExtendedInAnySuite = suites.contains { otherSuite in
                    otherSuite.classExtensions.contains { $0.extends == name }
                }

                if debug {
                    print("DEBUG: Checking standard class '\(name)' for suite '\(suite.name)': mergedWithStandard=\(mergedWithStandardClasses.contains(name)), hasInSuite=\(mergedClasses.contains(where: { $0.name == name })), wasExtended=\(wasExtendedInAnySuite)")
                }

                if !mergedWithStandardClasses.contains(name) &&
                   !mergedClasses.contains(where: { $0.name == name }) &&
                   !wasExtendedInAnySuite {
                    if debug {
                        print("DEBUG: Adding unmerged standard class '\(name)' to suite '\(suite.name)'")
                    }
                    mergedClasses.append(standardClass)
                } else if debug {
                    print("DEBUG: Skipping standard class '\(name)' in suite '\(suite.name)' (merged=\(mergedWithStandardClasses.contains(name)), hasInSuite=\(mergedClasses.contains(where: { $0.name == name })), wasExtended=\(wasExtendedInAnySuite))")
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

        if verbose {
            print("Parsing suite: \(name)")
        }

        if debug {
            print("DEBUG: parseSuite '\(name)' - looking for class-extension elements")
        }

        let classes = try parseClasses(from: element)
        let enumerations = try parseEnumerations(from: element)
        let commands = try parseCommands(from: element)
        let classExtensions = try parseClassExtensions(from: element)

        if debug {
            print("DEBUG: parseSuite '\(name)' found \(classExtensions.count) class extensions")
        }

        if verbose {
            print("Suite '\(name)' has \(commands.count) commands")
        }

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
        let recordTypeElements = try element.nodes(forXPath: ".//record-type")
        var classes: [SDEFClass] = []

        // Parse regular class elements
        for classNode in classElements {
            guard let classElement = classNode as? XMLElement else { continue }

            let isHidden = classElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let sdefClass = try parseClass(from: classElement)
            classes.append(sdefClass)
        }

        // Parse record-type elements as classes
        for recordNode in recordTypeElements {
            guard let recordElement = recordNode as? XMLElement else { continue }

            let isHidden = recordElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let sdefClass = try parseRecordType(from: recordElement)
            classes.append(sdefClass)
        }

        return classes
    }

    func parseRecordType(from element: XMLElement) throws -> SDEFClass {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let inherits = element.attribute(forName: "inherits")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"

        let properties = try parseProperties(from: element)
        // Record types don't have elements, responds-to, or class extensions
        let elements: [SDEFElement] = []
        let respondsTo: [String] = []

        return SDEFClass(
            name: name,
            pluralName: nil, // Record types don't have plural names
            code: code,
            description: description,
            inherits: inherits,
            properties: properties,
            elements: elements,
            respondsTo: respondsTo,
            isHidden: isHidden
        )
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

        if debug {
            print("DEBUG: parseClassExtensions called - element name: '\(element.name ?? "nil")'")
            print("DEBUG: parseClassExtensions XPath './/class-extension' found \(extensionElements.count) elements")
            // Try alternative XPath expressions
            do {
                let altElements1 = try element.nodes(forXPath: "./class-extension")
                print("DEBUG: XPath './class-extension' found \(altElements1.count) elements")
                let altElements2 = try element.nodes(forXPath: "class-extension")
                print("DEBUG: XPath 'class-extension' found \(altElements2.count) elements")
            } catch {
                print("DEBUG: Alternative XPath failed: \(error)")
            }
        }

        for extensionNode in extensionElements {
            guard let extensionElement = extensionNode as? XMLElement else { continue }

            let extends = extensionElement.attribute(forName: "extends")?.stringValue ?? ""
            let properties = try parseProperties(from: extensionElement)
            let elements = try parseElements(from: extensionElement)
            let respondsTo = try parseRespondsTo(from: extensionElement)

            if debug {
                print("DEBUG: Found class-extension extending '\(extends)' with \(elements.count) elements, \(properties.count) properties")
            }

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
        let description = element.attribute(forName: "description")?.stringValue

        // Try to find type element first
        if let typeElements = try? element.nodes(forXPath: ".//type"),
           let typeElement = typeElements.first as? XMLElement {
            let baseType = typeElement.attribute(forName: "type")?.stringValue ?? "Any"
            let isList = typeElement.attribute(forName: "list")?.stringValue == "yes"
            return SDEFPropertyType(baseType: baseType, isList: isList, isOptional: true, description: description)
        }

        // Fallback to type attribute
        let typeAttr = element.attribute(forName: "type")?.stringValue ?? "Any"
        return SDEFPropertyType(baseType: typeAttr, isList: false, isOptional: true, description: description)
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
        // Commands are direct children of suite, not nested deeper
        let commandElements = try element.nodes(forXPath: "./command")
        var commands: [SDEFCommand] = []

        if verbose {
            print("Found \(commandElements.count) command elements in suite")
        }

        for commandNode in commandElements {
            guard let commandElement = commandNode as? XMLElement else { continue }

            let isHidden = commandElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }

            let command = try parseCommand(from: commandElement)
            commands.append(command)

            if verbose {
                print("  - Parsed command: \(command.name)")
            }
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
