import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// Main command-line tool for generating Swift Scripting Bridge code from .sdef files
@main
struct SdefToSwift: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sdef2swift",
        abstract: "Generate Swift Scripting Bridge code from .sdef files",
        discussion: """
        This tool parses Apple Scripting Definition (.sdef) files and generates 
        Swift code for use with the Scripting Bridge framework, similar to 'sdp -f h' 
        but outputting Swift instead of Objective-C headers.
        
        The generated Swift code provides type-safe interfaces for controlling
        scriptable applications using the macOS Scripting Bridge framework.
        """
    )
    
    @Argument(help: "Path to the .sdef file to process")
    var sdefPath: String
    
    @Option(name: .shortAndLong, help: "Output directory (default: current directory)")
    var outputDirectory: String = "."
    
    @Option(name: .shortAndLong, help: "Base name for generated files (default: derived from sdef filename)")
    var basename: String?
    
    @Flag(name: .shortAndLong, help: "Include hidden definitions marked in the sdef")
    var includeHidden = false
    
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false
    
    func run() async throws {
        let sdefURL = URL(fileURLWithPath: sdefPath)
        
        // Validate input file
        guard FileManager.default.fileExists(atPath: sdefPath) else {
            throw ValidationError("SDEF file not found: \(sdefPath)")
        }
        
        guard sdefURL.pathExtension.lowercased() == "sdef" else {
            throw ValidationError("Input file must have .sdef extension")
        }
        
        // Validate output directory
        let outputURL = URL(fileURLWithPath: outputDirectory)
        if !FileManager.default.fileExists(atPath: outputDirectory) {
            do {
                try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
            } catch {
                throw ValidationError("Cannot create output directory: \(outputDirectory)")
            }
        }
        
        // Determine base name
        let finalBasename = basename ?? sdefURL.deletingPathExtension().lastPathComponent
        
        // Validate base name
        guard !finalBasename.isEmpty && finalBasename.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            throw ValidationError("Invalid base name. Must contain only letters, numbers, and underscores.")
        }
        
        if verbose {
            print("Processing: \(sdefPath)")
            print("Base name: \(finalBasename)")
            print("Output directory: \(outputDirectory)")
        }
        
        do {
            let generator = SdefSwiftGenerator(
                sdefURL: sdefURL,
                basename: finalBasename,
                outputDirectory: outputDirectory,
                includeHidden: includeHidden,
                verbose: verbose
            )
            
            let outputURL = try await generator.generate()
            print("Generated Swift file: \(outputURL.path)")
            
        } catch let error as ValidationError {
            throw error
        } catch let error as RuntimeError {
            throw error
        } catch {
            throw RuntimeError("Failed to generate Swift code: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types

struct ValidationError: Error, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return message
    }
}

struct RuntimeError: Error, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return message
    }
}

// MARK: - SDEF Swift Generator

/// Main generator class that coordinates parsing and code generation
class SdefSwiftGenerator {
    private let sdefURL: URL
    private let basename: String
    private let outputDirectory: String
    private let includeHidden: Bool
    private let verbose: Bool
    
    init(sdefURL: URL, basename: String, outputDirectory: String, includeHidden: Bool, verbose: Bool) {
        self.sdefURL = sdefURL
        self.basename = basename
        self.outputDirectory = outputDirectory
        self.includeHidden = includeHidden
        self.verbose = verbose
    }
    
    func generate() async throws -> URL {
        // Parse the SDEF file
        let xmlData: Data
        do {
            xmlData = try Data(contentsOf: sdefURL)
        } catch {
            throw RuntimeError("Cannot read SDEF file: \(error.localizedDescription)")
        }
        
        let xmlDocument: XMLDocument
        do {
            xmlDocument = try XMLDocument(data: xmlData, options: [])
        } catch {
            throw RuntimeError("Invalid XML in SDEF file: \(error.localizedDescription)")
        }
        
        if verbose {
            print("Parsed SDEF XML successfully")
        }
        
        // Create the parser
        let parser = SdefParser(document: xmlDocument, includeHidden: includeHidden, verbose: verbose)
        let sdefModel: SdefModel
        do {
            sdefModel = try parser.parse()
        } catch {
            throw RuntimeError("Failed to parse SDEF structure: \(error.localizedDescription)")
        }
        
        if verbose {
            print("Extracted \(sdefModel.suites.count) suites")
            let totalClasses = sdefModel.suites.reduce(0) { $0 + $1.classes.count }
            let totalEnums = sdefModel.suites.reduce(0) { $0 + $1.enumerations.count }
            print("Found \(totalClasses) classes and \(totalEnums) enumerations")
        }
        
        // Generate Swift code
        let codeGenerator = SwiftCodeGenerator(model: sdefModel, basename: basename, verbose: verbose)
        let swiftCode: String
        do {
            swiftCode = try codeGenerator.generateCode()
        } catch {
            throw RuntimeError("Failed to generate Swift code: \(error.localizedDescription)")
        }
        
        // Write to output file
        let outputURL = URL(fileURLWithPath: outputDirectory)
            .appendingPathComponent("\(basename).swift")
        
        do {
            try swiftCode.write(to: outputURL, atomically: true, encoding: .utf8)
        } catch {
            throw RuntimeError("Cannot write output file: \(error.localizedDescription)")
        }
        
        return outputURL
    }
}

// MARK: - SDEF Model

struct SdefModel {
    let suites: [Suite]
}

struct Suite {
    let name: String
    let code: String
    let description: String?
    let classes: [SdefClass]
    let enumerations: [Enumeration]
    let commands: [Command]
    let classExtensions: [ClassExtension]
}

struct SdefClass {
    let name: String
    let pluralName: String?
    let code: String
    let description: String?
    let inherits: String?
    let properties: [Property]
    let elements: [Element]
    let respondsTo: [String]
    let isHidden: Bool
}

struct ClassExtension {
    let extends: String
    let properties: [Property]
    let elements: [Element]
    let respondsTo: [String]
}

struct Property {
    let name: String
    let code: String
    let type: PropertyType
    let description: String?
    let access: String?
    let isHidden: Bool
}

struct Element {
    let type: String
    let cocoaKey: String?
}

struct PropertyType {
    let baseType: String
    let isList: Bool
    let isOptional: Bool
}

struct Enumeration {
    let name: String
    let code: String
    let description: String?
    let enumerators: [Enumerator]
    let isHidden: Bool
}

struct Enumerator {
    let name: String
    let code: String
    let description: String?
    let stringValue: String?
}

struct Command {
    let name: String
    let code: String
    let description: String?
    let directParameter: Parameter?
    let parameters: [Parameter]
    let result: PropertyType?
    let isHidden: Bool
}

struct Parameter {
    let name: String?
    let code: String
    let type: PropertyType
    let description: String?
    let isOptional: Bool
}

// MARK: - SDEF Parser

/// Parser that extracts structured data from SDEF XML documents
class SdefParser {
    private let document: XMLDocument
    private let includeHidden: Bool
    private let verbose: Bool
    
    init(document: XMLDocument, includeHidden: Bool, verbose: Bool) {
        self.document = document
        self.includeHidden = includeHidden
        self.verbose = verbose
    }
    
    func parse() throws -> SdefModel {
        guard let rootElement = document.rootElement() else {
            throw RuntimeError("Invalid SDEF: no root element")
        }
        
        let suites = try parseSuites(from: rootElement)
        return SdefModel(suites: suites)
    }
    
    private func parseSuites(from element: XMLElement) throws -> [Suite] {
        let suiteElements = try element.nodes(forXPath: ".//suite")
        var suites: [Suite] = []
        
        for suiteNode in suiteElements {
            guard let suiteElement = suiteNode as? XMLElement else { continue }
            
            let suite = try parseSuite(from: suiteElement)
            suites.append(suite)
        }
        
        return suites
    }
    
    private func parseSuite(from element: XMLElement) throws -> Suite {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        
        let classes = try parseClasses(from: element)
        let enumerations = try parseEnumerations(from: element)
        let commands = try parseCommands(from: element)
        let classExtensions = try parseClassExtensions(from: element)
        
        return Suite(
            name: name,
            code: code,
            description: description,
            classes: classes,
            enumerations: enumerations,
            commands: commands,
            classExtensions: classExtensions
        )
    }
    
    private func parseClasses(from element: XMLElement) throws -> [SdefClass] {
        let classElements = try element.nodes(forXPath: ".//class")
        var classes: [SdefClass] = []
        
        for classNode in classElements {
            guard let classElement = classNode as? XMLElement else { continue }
            
            let isHidden = classElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }
            
            let sdefClass = try parseClass(from: classElement)
            classes.append(sdefClass)
        }
        
        return classes
    }
    
    private func parseClass(from element: XMLElement) throws -> SdefClass {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let pluralName = element.attribute(forName: "plural")?.stringValue
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let inherits = element.attribute(forName: "inherits")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"
        
        let properties = try parseProperties(from: element)
        let elements = try parseElements(from: element)
        let respondsTo = try parseRespondsTo(from: element)
        
        return SdefClass(
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
    
    private func parseClassExtensions(from element: XMLElement) throws -> [ClassExtension] {
        let extensionElements = try element.nodes(forXPath: ".//class-extension")
        var extensions: [ClassExtension] = []
        
        for extensionNode in extensionElements {
            guard let extensionElement = extensionNode as? XMLElement else { continue }
            
            let extends = extensionElement.attribute(forName: "extends")?.stringValue ?? ""
            let properties = try parseProperties(from: extensionElement)
            let elements = try parseElements(from: extensionElement)
            let respondsTo = try parseRespondsTo(from: extensionElement)
            
            let classExtension = ClassExtension(
                extends: extends,
                properties: properties,
                elements: elements,
                respondsTo: respondsTo
            )
            
            extensions.append(classExtension)
        }
        
        return extensions
    }
    
    private func parseProperties(from element: XMLElement) throws -> [Property] {
        let propertyElements = try element.nodes(forXPath: ".//property")
        var properties: [Property] = []
        
        for propertyNode in propertyElements {
            guard let propertyElement = propertyNode as? XMLElement else { continue }
            
            let isHidden = propertyElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }
            
            let property = try parseProperty(from: propertyElement)
            properties.append(property)
        }
        
        return properties
    }
    
    private func parseProperty(from element: XMLElement) throws -> Property {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let access = element.attribute(forName: "access")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"
        
        let type = try parsePropertyType(from: element)
        
        return Property(
            name: name,
            code: code,
            type: type,
            description: description,
            access: access,
            isHidden: isHidden
        )
    }
    
    private func parsePropertyType(from element: XMLElement) throws -> PropertyType {
        // Try to find type element first
        if let typeElements = try? element.nodes(forXPath: ".//type"),
           let typeElement = typeElements.first as? XMLElement {
            let baseType = typeElement.attribute(forName: "type")?.stringValue ?? "Any"
            let isList = typeElement.attribute(forName: "list")?.stringValue == "yes"
            return PropertyType(baseType: baseType, isList: isList, isOptional: true)
        }
        
        // Fallback to type attribute
        let typeAttr = element.attribute(forName: "type")?.stringValue ?? "Any"
        return PropertyType(baseType: typeAttr, isList: false, isOptional: true)
    }
    
    private func parseElements(from element: XMLElement) throws -> [Element] {
        let elementElements = try element.nodes(forXPath: ".//element")
        var elements: [Element] = []
        
        for elementNode in elementElements {
            guard let elementElement = elementNode as? XMLElement else { continue }
            
            let type = elementElement.attribute(forName: "type")?.stringValue ?? ""
            let cocoaKey = elementElement.attribute(forName: "key")?.stringValue
            
            let elementObj = Element(type: type, cocoaKey: cocoaKey)
            elements.append(elementObj)
        }
        
        return elements
    }
    
    private func parseRespondsTo(from element: XMLElement) throws -> [String] {
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
    
    private func parseEnumerations(from element: XMLElement) throws -> [Enumeration] {
        let enumElements = try element.nodes(forXPath: ".//enumeration")
        var enumerations: [Enumeration] = []
        
        for enumNode in enumElements {
            guard let enumElement = enumNode as? XMLElement else { continue }
            
            let isHidden = enumElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }
            
            let enumeration = try parseEnumeration(from: enumElement)
            enumerations.append(enumeration)
        }
        
        return enumerations
    }
    
    private func parseEnumeration(from element: XMLElement) throws -> Enumeration {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"
        
        let enumerators = try parseEnumerators(from: element)
        
        return Enumeration(
            name: name,
            code: code,
            description: description,
            enumerators: enumerators,
            isHidden: isHidden
        )
    }
    
    private func parseEnumerators(from element: XMLElement) throws -> [Enumerator] {
        let enumeratorElements = try element.nodes(forXPath: ".//enumerator")
        var enumerators: [Enumerator] = []
        
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
            
            let enumerator = Enumerator(
                name: name,
                code: code,
                description: description,
                stringValue: stringValue
            )
            
            enumerators.append(enumerator)
        }
        
        return enumerators
    }
    
    private func parseCommands(from element: XMLElement) throws -> [Command] {
        let commandElements = try element.nodes(forXPath: ".//command")
        var commands: [Command] = []
        
        for commandNode in commandElements {
            guard let commandElement = commandNode as? XMLElement else { continue }
            
            let isHidden = commandElement.attribute(forName: "hidden")?.stringValue == "yes"
            if isHidden && !includeHidden { continue }
            
            let command = try parseCommand(from: commandElement)
            commands.append(command)
        }
        
        return commands
    }
    
    private func parseCommand(from element: XMLElement) throws -> Command {
        let name = element.attribute(forName: "name")?.stringValue ?? ""
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let isHidden = element.attribute(forName: "hidden")?.stringValue == "yes"
        
        // Parse direct parameter
        var directParameter: Parameter?
        if let directParamElements = try? element.nodes(forXPath: ".//direct-parameter"),
           let directParamElement = directParamElements.first as? XMLElement {
            directParameter = try parseParameter(from: directParamElement, name: nil)
        }
        
        // Parse parameters
        let parameterElements = try element.nodes(forXPath: ".//parameter")
        var parameters: [Parameter] = []
        for paramNode in parameterElements {
            guard let paramElement = paramNode as? XMLElement else { continue }
            let paramName = paramElement.attribute(forName: "name")?.stringValue
            let parameter = try parseParameter(from: paramElement, name: paramName)
            parameters.append(parameter)
        }
        
        // Parse result type
        var result: PropertyType?
        if let resultElements = try? element.nodes(forXPath: ".//result"),
           let resultElement = resultElements.first as? XMLElement {
            result = try parsePropertyType(from: resultElement)
        }
        
        return Command(
            name: name,
            code: code,
            description: description,
            directParameter: directParameter,
            parameters: parameters,
            result: result,
            isHidden: isHidden
        )
    }
    
    private func parseParameter(from element: XMLElement, name: String?) throws -> Parameter {
        let code = element.attribute(forName: "code")?.stringValue ?? ""
        let description = element.attribute(forName: "description")?.stringValue
        let isOptional = element.attribute(forName: "optional")?.stringValue == "yes"
        
        let type = try parsePropertyType(from: element)
        
        return Parameter(
            name: name,
            code: code,
            type: type,
            description: description,
            isOptional: isOptional
        )
    }
}

// MARK: - Swift Code Generator

/// Generates Swift source code from parsed SDEF model
class SwiftCodeGenerator {
    private let model: SdefModel
    private let basename: String
    private let verbose: Bool
    
    init(model: SdefModel, basename: String, verbose: Bool) {
        self.model = model
        self.basename = basename
        self.verbose = verbose
    }
    
    func generateCode() throws -> String {
        var code = """
        //
        // \(basename).swift
        // Generated by sdef2swift
        //
        
        import Foundation
        import ScriptingBridge
        
        """
        
        // Generate type aliases for common ScriptingBridge types
        code += generateTypeAliases()
        
        // Generate enumerations first
        for suite in model.suites {
            for enumeration in suite.enumerations {
                code += generateEnumeration(enumeration)
            }
        }
        
        // Generate protocols for classes
        for suite in model.suites {
            for sdefClass in suite.classes {
                code += generateClassProtocol(sdefClass, suite: suite)
            }
            
            // Generate protocols for class extensions
            for classExtension in suite.classExtensions {
                code += generateClassExtensionProtocol(classExtension, suite: suite)
            }
        }
        
        // Generate main application protocol
        code += generateApplicationProtocol()
        
        // Generate SBApplication extension
        code += generateSBApplicationExtension()
        
        return code
    }
    
    private func generateTypeAliases() -> String {
        return """
        
        // MARK: - Type Aliases
        
        public typealias \(basename)Application = SBApplication
        public typealias \(basename)Object = SBObject
        public typealias \(basename)ElementArray = SBElementArray
        
        """
    }
    
    private func generateEnumeration(_ enumeration: Enumeration) -> String {
        let enumName = "\(basename)\(enumeration.name.capitalizingFirstLetter().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: ""))"
        
        var code = """
        
        // MARK: - \(enumeration.name)
        
        """
        
        if let description = enumeration.description {
            code += "/// \(description)\n"
        }
        
        code += "@objc public enum \(enumName): AEKeyword {\n"
        
        for enumerator in enumeration.enumerators {
            if let description = enumerator.description {
                code += "    /// \(description)\n"
            }
            
            let caseName = swiftCaseName(enumerator.name)
            let codeValue = formatEnumeratorCode(enumerator.code)
            code += "    case \(caseName) = \(codeValue)\n"
        }
        
        code += "}\n"
        
        return code
    }
    
    private func generateClassProtocol(_ sdefClass: SdefClass, suite: Suite) -> String {
        let protocolName = "\(basename)\(sdefClass.name.capitalizingFirstLetter().replacingOccurrences(of: " ", with: ""))"
        
        var code = """
        
        // MARK: - \(sdefClass.name)
        
        """
        
        if let description = sdefClass.description {
            code += "/// \(description)\n"
        }
        
        var inheritanceList = ["SBObject"]
        if let inherits = sdefClass.inherits {
            let cleanInherits = inherits.capitalizingFirstLetter().replacingOccurrences(of: " ", with: "")
            inheritanceList.append("\(basename)\(cleanInherits)")
        }
        
        code += "@objc public protocol \(protocolName): \(inheritanceList.joined(separator: ", ")) {\n"
        
        // Generate properties
        for property in sdefClass.properties {
            code += generateProperty(property)
        }
        
        // Generate element arrays
        for element in sdefClass.elements {
            let methodName = element.type.lowercased() + "s"
            code += "    @objc optional func \(methodName)() -> SBElementArray\n"
        }
        
        code += "}\n"
        
        // Generate SBObject extension
        code += """
        
        extension SBObject: \(protocolName) {}
        
        """
        
        return code
    }
    
    private func generateClassExtensionProtocol(_ classExtension: ClassExtension, suite: Suite) -> String {
        let baseTypeName = classExtension.extends.capitalizingFirstLetter().replacingOccurrences(of: " ", with: "")
        let protocolName = "\(basename)\(baseTypeName)"
        
        var code = """

        // MARK: - \(classExtension.extends) Extension
        
        @objc public protocol \(protocolName): SBObject {
        
        """
        
        // Generate properties
        for property in classExtension.properties {
            code += generateProperty(property)
        }
        
        // Generate element arrays
        for element in classExtension.elements {
            let methodName = element.type.lowercased() + "s"
            code += "    @objc optional func \(methodName)() -> SBElementArray\n"
        }
        
        code += "}\n"
        
        // Generate SBObject extension
        code += """
        
        extension SBObject: \(protocolName) {}
        
        """
        
        return code
    }
    
    private func generateProperty(_ property: Property) -> String {
        var code = ""
        
        if let description = property.description {
            code += "    /// \(description)\n"
        }
        
        let propertyName = swiftPropertyName(property.name)
        let swiftType = swiftType(for: property.type)
        
        let readOnly = property.access == "r" ? " { get }" : " { get set }"
        
        code += "    @objc optional var \(propertyName): \(swiftType)\(readOnly)\n"
        
        return code
    }
    
    private func generateApplicationProtocol() -> String {
        return """
        
        // MARK: - Application Protocol
        
        @objc public protocol \(basename)ApplicationProtocol: SBApplicationProtocol {
            @objc optional func documents() -> SBElementArray
            @objc optional func windows() -> SBElementArray
        }
        
        """
    }
    
    private func generateSBApplicationExtension() -> String {
        return """
        extension SBApplication: \(basename)ApplicationProtocol {}
        
        """
    }
    
    // MARK: - Helper Methods
    
    private func swiftType(for propertyType: PropertyType) -> String {
        var baseType = swiftTypeName(propertyType.baseType)
        
        if propertyType.isList {
            baseType = "[\(baseType)]"
        }
        
        if propertyType.isOptional {
            baseType += "?"
        }
        
        return baseType
    }
    
    private func swiftTypeName(_ objcType: String) -> String {
        switch objcType.lowercased() {
        case "text", "string":
            return "String"
        case "integer", "int":
            return "Int"
        case "real", "double":
            return "Double"
        case "boolean", "bool":
            return "Bool"
        case "date":
            return "Date"
        case "file", "alias":
            return "URL"
        case "record":
            return "[String: Any]"
        case "any":
            return "Any"
        case "missing value":
            return "NSNull"
        default:
            // Assume it's a class name - clean up the name
            let cleanType = objcType
                .capitalizingFirstLetter()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
            return "\(basename)\(cleanType)"
        }
    }
    
    private func swiftPropertyName(_ name: String) -> String {
        let sanitized = name
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
        return sanitized.lowercaseFirstLetter()
    }
    
    private func swiftCaseName(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
        
        return cleaned.lowercaseFirstLetter()
    }
    
    private func formatEnumeratorCode(_ code: String) -> String {
        // Convert 4-character codes to proper format
        if code.count == 4 {
            let chars = Array(code)
            let formatted = chars.compactMap { char in
                guard let ascii = char.asciiValue else { return "00" }
                return String(format: "%02x", ascii)
            }.joined()
            return "0x\(formatted)"
        }
        // Handle other code formats
        if code.hasPrefix("0x") || code.allSatisfy({ $0.isHexDigit }) {
            return code.hasPrefix("0x") ? code : "0x\(code)"
        }
        return "'\(code)'"
    }
}

// MARK: - String Extensions

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    func lowercaseFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
}