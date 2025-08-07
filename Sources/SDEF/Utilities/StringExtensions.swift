//
// StringExtensions.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

// MARK: - Swift Naming Extensions

public extension String {
    /// A Swift type name by capitalising the first letter.
    ///
    /// This computed property transforms strings into proper Swift type names by ensuring the first
    /// character is uppercase while preserving the case of all other characters. It's
    /// commonly used for converting bundle identifiers and SDEF class names to Swift types.
    ///
    /// - Returns: A string suitable for Swift type naming (capitalised first letter)
    @inlinable
    var asSwiftTypeName: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Returns a copy of the string with the first character capitalised.
    ///
    /// This method converts the first character of the string to uppercase while
    /// leaving the rest of the string unchanged. It's commonly used for converting
    /// identifiers to proper Swift type names and method names.
    ///
    /// - Returns: A string with the first character capitalised
    @inlinable
    func capitalisingFirstLetter() -> String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Returns a copy of the string with the first character in lowercase.
    ///
    /// This method converts the first character of the string to lowercase while
    /// preserving the case of all other characters. It's used for generating
    /// proper Swift property and variable names from SDEF identifiers.
    ///
    /// - Returns: A string with the first character in lowercase
    @inlinable
    func lowercasingFirstLetter() -> String {
        guard !isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}
