//
// BundleUtilities.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Utilities for working with macOS application bundle identifiers.
///
/// This struct provides helper methods for processing bundle identifiers commonly used
/// in scriptable applications, including extracting application names and converting
/// them to proper Swift naming conventions for code generation.
public struct BundleUtilities {
    /// Extract the application name from a bundle identifier and convert it to Swift type naming.
    ///
    /// This method takes a reverse-DNS bundle identifier (e.g., "com.apple.Music") and extracts
    /// the final component as the application name, then ensures it follows Swift type naming
    /// conventions by capitalising the first letter.
    ///
    /// Examples:
    /// - `"com.apple.Music"` → `"Music"`
    /// - `"com.apple.iCal"` → `"ICal"`
    /// - `"org.example.myApp"` → `"MyApp"`
    ///
    /// - Parameter bundleIdentifier: The bundle identifier to process
    /// - Returns: The extracted application name suitable for Swift type naming
    @inlinable
    public static func extractBasename(from bundleIdentifier: String) -> String {
        extractRawBasename(from: bundleIdentifier).asSwiftTypeName
    }

    /// Extract the raw application name from a bundle identifier without Swift naming conversion.
    ///
    /// This method extracts just the final component of a bundle identifier without
    /// applying any naming transformations. Useful when you need the original name
    /// for file operations or other non-Swift contexts.
    ///
    /// Examples:
    /// - `"com.apple.Music"` → `"Music"`
    /// - `"com.apple.iCal"` → `"iCal"`
    /// - `"org.example.myApp"` → `"myApp"`
    ///
    /// - Parameter bundleIdentifier: The bundle identifier to process
    /// - Returns: The raw application name without naming transformations
    @inlinable
    public static func extractRawBasename(from bundleIdentifier: String) -> String {
        bundleIdentifier.split(separator: ".").last.map(String.init) ?? bundleIdentifier
    }
}
