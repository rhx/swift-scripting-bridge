//
// StringExtensions.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

// MARK: - Swift Naming Extensions

extension StringProtocol {
    /// A Swift type name by capitalising the first letter.
    ///
    /// This computed property transforms strings into proper Swift type names by ensuring the first
    /// character is uppercase while preserving the case of all other characters. It's
    /// commonly used for converting bundle identifiers and SDEF class names to Swift types.
    ///
    /// - Returns: A string suitable for Swift type naming (capitalised first letter)
    @usableFromInline var asSwiftTypeName: String {
        guard !isEmpty else { return String(self) }
        return prefix(1).uppercased() + dropFirst()
    }

    /// A copy of the string with the first character capitalised.
    ///
    /// This computed property converts the first character of the string to uppercase while
    /// leaving the rest of the string unchanged. It's commonly used for converting
    /// identifiers to proper Swift type names and method names.
    ///
    /// - Returns: A string with the first character capitalised
    @usableFromInline var capitalisedFirstLetter: String {
        guard !isEmpty else { return String(self) }
        return prefix(1).uppercased() + dropFirst()
    }

    /// A copy of the string with the first character in lowercase.
    ///
    /// This computed property converts the first character of the string to lowercase while
    /// preserving the case of all other characters. It's used for generating
    /// proper Swift property and variable names from SDEF identifiers.
    ///
    /// - Returns: A string with the first character in lowercase
    @usableFromInline var lowercasedFirstLetter: String {
        guard !isEmpty else { return String(self) }
        return prefix(1).lowercased() + dropFirst()
    }

    /// A Swift property name suitable for camelCase naming conventions.
    ///
    /// This computed property converts SDEF property names to proper Swift property naming
    /// by splitting on spaces, hyphens, and underscores, then joining in camelCase format.
    /// Special acronyms like URL, ID, UUID are handled appropriately.
    ///
    /// - Returns: A camelCase property name suitable for Swift properties
    @usableFromInline var swiftPropertyName: String {
        // Split by spaces, hyphens, and underscores
        let words = components(separatedBy: CharacterSet(charactersIn: " -_"))
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return String(escapedReservedKeyword) }

        // Process each word
        var processedWords: [String] = []

        for (index, word) in words.enumerated() {
            let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanWord.isEmpty else { continue }

            // Handle special cases that should remain uppercase
            let upperWord = cleanWord.uppercased()
            if index == 0 {
                // First word should be lowercase, except for special cases
                if upperWord == "URL" || upperWord == "UUID" || upperWord == "ID" ||
                    upperWord == "HTTP" || upperWord == "HTTPS" || upperWord == "XML" ||
                    upperWord == "HTML" || upperWord == "PDF" || upperWord == "UI" ||
                    upperWord == "API" {
                    processedWords.append(cleanWord.lowercased())
                } else {
                    processedWords.append(cleanWord.lowercased())
                }
            } else if upperWord == "CD" || upperWord == "DVD" || upperWord == "URL" ||
                        upperWord == "ID" || upperWord == "UUID" || upperWord == "HTTP" ||
                        upperWord == "HTTPS" || upperWord == "XML" || upperWord == "HTML" ||
                        upperWord == "PDF" || upperWord == "UI" || upperWord == "API" {
                processedWords.append(upperWord)
            } else {
                // Subsequent words should be capitalised
                processedWords.append(cleanWord.capitalisedFirstLetter)
            }
        }

        let result = processedWords.joined()
        return result.escapedReservedKeyword
    }

    /// A Swift method name suitable for camelCase naming conventions.
    ///
    /// This computed property converts SDEF method names to proper Swift method naming
    /// by splitting on spaces, hyphens, and underscores, then joining in camelCase format.
    /// Special acronyms are handled appropriately.
    ///
    /// - Returns: A camelCase method name suitable for Swift methods
    @usableFromInline var swiftMethodName: String {
        // Split by spaces, hyphens, and underscores
        let words = components(separatedBy: CharacterSet(charactersIn: " -_"))
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return String(self) }

        // Process each word
        var processedWords: [String] = []

        for (index, word) in words.enumerated() {
            let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanWord.isEmpty else { continue }

            // Handle special cases that should remain uppercase
            let upperWord = cleanWord.uppercased()
            if upperWord == "CD" || upperWord == "DVD" || upperWord == "URL" ||
                upperWord == "ID" || upperWord == "UUID" || upperWord == "HTTP" ||
                upperWord == "HTTPS" || upperWord == "XML" || upperWord == "HTML" ||
                upperWord == "PDF" || upperWord == "UI" || upperWord == "API" {
                processedWords.append(upperWord)
            } else if index == 0 {
                // First word should be lowercase
                processedWords.append(cleanWord.lowercased())
            } else {
                // Subsequent words should be capitalised
                processedWords.append(cleanWord.capitalisedFirstLetter)
            }
        }

        return processedWords.joined()
    }

    /// A Swift class name suitable for PascalCase naming conventions.
    ///
    /// This computed property converts SDEF class names to proper Swift class naming
    /// by splitting on spaces, hyphens, and underscores, then joining in PascalCase format.
    /// Special acronyms are handled appropriately.
    ///
    /// - Returns: A PascalCase class name suitable for Swift types
    @usableFromInline var swiftClassName: String {
        // First, handle special characters that need replacement
        let cleanedString = replacingOccurrences(of: "#", with: "Hash")
            .replacingOccurrences(of: "&", with: "And")
            .replacingOccurrences(of: "+", with: "Plus")
            .replacingOccurrences(of: "=", with: "Equals")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "/", with: "Or")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "*", with: "Star")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "@", with: "At")
            .replacingOccurrences(of: "%", with: "Percent")
            .replacingOccurrences(of: "^", with: "")
            .replacingOccurrences(of: "~", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "|", with: "Or")

        // Split by spaces, hyphens, and underscores
        let words = cleanedString.components(separatedBy: CharacterSet(charactersIn: " -_"))
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return String(cleanedString) }

        // Process each word by capitalising first letter
        var processedWords: [String] = []

        for word in words {
            let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanWord.isEmpty else { continue }

            // Handle special cases that should remain uppercase
            let upperWord = cleanWord.uppercased()
            if upperWord == "CD" || upperWord == "DVD" || upperWord == "URL" ||
                upperWord == "ID" || upperWord == "UUID" || upperWord == "HTTP" ||
                upperWord == "HTTPS" || upperWord == "XML" || upperWord == "HTML" ||
                upperWord == "PDF" || upperWord == "UI" || upperWord == "API" {
                processedWords.append(upperWord)
            } else {
                // All words should be capitalised for type names
                processedWords.append(cleanWord.capitalisedFirstLetter)
            }
        }

        return processedWords.joined()
    }

    /// Escape the string if it conflicts with Swift reserved keywords.
    ///
    /// This computed property checks if the string matches any Swift reserved keywords
    /// and wraps it in backticks if necessary to make it a valid Swift identifier.
    ///
    /// - Returns: The string wrapped in backticks if it's a reserved keyword, unchanged otherwise
    @usableFromInline var escapedReservedKeyword: Self {
        let swiftKeywords: [Self] = [
            "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func",
            "import", "init", "inout", "internal", "let", "open", "operator", "private",
            "protocol", "public", "rethrows", "static", "struct", "subscript", "typealias",
            "var", "break", "case", "continue", "default", "defer", "do", "else", "fallthrough",
            "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while",
            "as", "Any", "catch", "false", "is", "nil", "super", "self", "Self", "throw",
            "throws", "true", "try", "associativity", "convenience", "dynamic", "didSet",
            "final", "get", "infix", "indirect", "lazy", "left", "mutating", "none",
            "nonmutating", "optional", "override", "postfix", "precedence", "prefix",
            "Protocol", "required", "right", "set", "Type", "unowned", "weak", "willSet"
        ]

        if swiftKeywords.contains(self) {
            return "`\(self)`"
        }
        return self
    }

    // MARK: - Code Generation Utilities

    /// Sanitise command codes to make them valid Swift identifiers.
    ///
    /// This computed property removes spaces and special characters from command codes,
    /// replacing them with readable alternatives to create valid Swift identifiers.
    /// If the result doesn't start with a letter or underscore, it's prefixed with
    /// an underscore to ensure validity.
    ///
    /// - Returns: A sanitised string suitable for use as a Swift identifier
    @usableFromInline var sanitisedCommandCode: String {
        let sanitised = replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "*", with: "Star")
            .replacingOccurrences(of: "/", with: "Slash")
            .replacingOccurrences(of: "+", with: "Plus")
            .replacingOccurrences(of: "-", with: "Minus")
            .replacingOccurrences(of: ".", with: "Dot")

        // Ensure it starts with a letter or underscore
        if let first = sanitised.first, !first.isLetter && first != "_" {
            return "_" + sanitised
        }
        return sanitised
    }

    /// Convert parameter names to Swift camelCase convention.
    ///
    /// This computed property transforms parameter names by splitting on spaces,
    /// lowercasing the first component, and capitalising subsequent components.
    /// The result is escaped if it conflicts with Swift reserved keywords.
    ///
    /// - Returns: A camelCase parameter name suitable for Swift code
    @usableFromInline var swiftParameterName: String {
        let components = split(separator: " ")
        guard !components.isEmpty else { return String(self) }

        var result = String(components[0]).lowercased()
        for component in components.dropFirst() {
            result += component.capitalized
        }
        return result.escapedReservedKeyword
    }

    /// Convert parameter names to Objective-C selector convention.
    ///
    /// This computed property transforms parameter names by splitting on spaces,
    /// lowercasing the first component, and capitalising subsequent components.
    /// Unlike swiftParameterName, this doesn't escape reserved keywords since
    /// Objective-C selectors don't require escaping.
    ///
    /// - Returns: A camelCase parameter name suitable for Objective-C selectors
    @usableFromInline var objcParameterName: String {
        let components = split(separator: " ")
        guard !components.isEmpty else { return String(self) }

        var result = String(components[0]).lowercased()
        for component in components.dropFirst() {
            result += component.capitalized
        }
        return result // No backtick escaping for @objc selectors
    }

    /// Convert names to Swift enumeration case naming convention.
    ///
    /// This computed property removes spaces, hyphens, and underscores from the string
    /// and converts the result to lowercase with the first letter remaining lowercase.
    /// This creates valid Swift enumeration case names.
    ///
    /// - Returns: A lowercase name suitable for Swift enumeration cases
    @usableFromInline var swiftCaseName: String {
        let cleaned = replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "&", with: "And")
            .replacingOccurrences(of: "#", with: "Hash")
            .replacingOccurrences(of: "+", with: "Plus")
            .replacingOccurrences(of: "=", with: "Equals")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "/", with: "Or")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "*", with: "Star")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "@", with: "At")
            .replacingOccurrences(of: "%", with: "Percent")
            .replacingOccurrences(of: "^", with: "")
            .replacingOccurrences(of: "~", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "|", with: "Or")
        return cleaned.lowercasedFirstLetter
    }

    /// Format four-character codes to proper hexadecimal representation.
    ///
    /// This computed property converts four-character Apple Event codes to their
    /// hexadecimal representation suitable for use in Swift enumerations.
    /// It handles various input formats and ensures consistent output.
    ///
    /// - Returns: A properly formatted hexadecimal code string
    @usableFromInline var formattedEnumeratorCode: String {
        // Convert 4-character codes to proper format
        if count == 4 {
            let chars = Array(self)
            let formatted = chars.compactMap { char in
                guard let ascii = char.asciiValue else { return "00" }
                return String(format: "%02x", ascii)
            }.joined()
            return "0x\(formatted)"
        }

        // Handle other code formats
        if hasPrefix("0x") || allSatisfy({ $0.isHexDigit }) {
            return hasPrefix("0x") ? String(self) : "0x\(self)"
        }
        return "'\(self)'"
    }

    /// Transform a class name into a proper Swift enum case name.
    ///
    /// This method converts class names by removing quotes and hyphens,
    /// capitalising words, and then converting to camelCase for the enum case.
    ///
    /// - Parameter name: The original class name from the SDEF
    /// - Returns: A properly formatted Swift enum case name
    @usableFromInline var asEnumCase: String {
        // Remove quotes and replace special characters with spaces or appropriate replacements
        let transformed = replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "&", with: "And")
            .replacingOccurrences(of: "#", with: "Hash")
            .replacingOccurrences(of: "+", with: "Plus")
            .replacingOccurrences(of: "=", with: "Equals")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "/", with: "Or")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "*", with: "Star")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "@", with: "At")
            .replacingOccurrences(of: "%", with: "Percent")
            .replacingOccurrences(of: "^", with: "")
            .replacingOccurrences(of: "~", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "|", with: "Or")

        // Capitalise each word and remove spaces
        let words = transformed.components(separatedBy: " ")
        let capitalised = words.map { $0.capitalisedFirstLetter }.joined()

        // Convert to camelCase (first letter lowercase)
        return capitalised.lowercasedFirstLetter
    }

    /// Return the base type for the receiver.
    ///
    /// This property returns the first component
    /// of a dotted type (or the while type if there is no '.').
    ///
    /// - Returns: First component of the dotted type.
    @usableFromInline var baseType: String {
        guard let baseType = split(separator: ".").first else {
            return String(self)
        }
        return String(baseType)
    }

    /// Transform an SDEF type name into a proper Swift type name.
    ///
    /// This property returns a Swift type name for the receiver,
    /// or `nil` if the type is not recognised.
    ///
    /// - Returns: A properly formatted Swift type name or `nil` if the type is not recognised.
    @usableFromInline var typeName: String? {
        switch baseType.lowercased() {
        case "text", "string":
            // If original type was "text.ctxt" or similar, it refers to a Text class,
            // not a String
            contains(".") ? "Text" : "String"
        case "integer", "int":
            "Int"
        case "real", "double":
            "Double"
        case "boolean", "bool":
            "Bool"
        case "date":
            "Date"
        case "file", "alias":
            "URL"
        case "record":
            "[String: Any]"
        case "any":
            "Any"
        case "missing value":
            "NSNull"
        case "rectangle":
            "NSRect"
        case "number":
            "NSNumber"
        case "point":
            "NSPoint"
        case "size":
            "NSSize"
        case "specifier":
            "SBObject"
        case "location specifier":
            "SBObject"
        case "type":
            "OSType"
        case "picture":
            "NSImage"
        case "enum":
            "OSType"
        case "double integer":
            "Int64"
        case "list":
            "SBElementArray"
        case "property":
            "SBObject"
        // Legacy Mac icon resource types - map to NSData for binary data
        case "icn#", "icnhash":
            "NSData"
        case "ics#", "icshash":
            "NSData"
        case "l8mk":
            "NSData"
        case "il32":
            "NSData"
        case "icl8":
            "NSData"
        case "icl4":
            "NSData"
        case "s8mk":
            "NSData"
        case "is32":
            "NSData"
        case "ics8":
            "NSData"
        case "ics4":
            "NSData"
        default:
            nil
        }
    }
}
