//
// CodeGenerationErrors.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

import Foundation

/// Errors that can occur during Swift code generation from SDEF models.
///
/// These errors indicate problems encountered while transforming SDEF model data
/// into Swift source code, such as unsupported type definitions or invalid
/// naming conventions that cannot be mapped to valid Swift identifiers.
public enum SDEFCodeGenerationError: Error {
    /// An unsupported SDEF type was encountered that cannot be mapped to Swift.
    ///
    /// This error occurs when the SDEF file contains type definitions that
    /// don't have corresponding Swift representations in the Scripting Bridge framework.
    case unsupportedType(String)

    /// An invalid identifier name was found that cannot be converted to valid Swift.
    ///
    /// This error is thrown when SDEF identifiers contain characters or patterns
    /// that cannot be transformed into legal Swift identifiers, even after
    /// applying standard naming transformations.
    case invalidIdentifier(String)

    /// A structural problem in the SDEF model prevents code generation.
    ///
    /// This error indicates fundamental issues with the SDEF model structure,
    /// such as missing required elements, circular dependencies, or other
    /// structural problems that make code generation impossible.
    case invalidModel(String)
}

extension SDEFCodeGenerationError: LocalizedError {
    /// A localised description of the code generation error.
    ///
    /// Provides detailed error messages that explain what went wrong during the
    /// Swift code generation process. These messages are designed to help developers
    /// understand and resolve issues with their SDEF files or generation configuration.
    ///
    /// - Returns: A descriptive error message suitable for display or logging
    public var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "Unsupported SDEF type: \(type)"
        case .invalidIdentifier(let identifier):
            return "Invalid Swift identifier: \(identifier)"
        case .invalidModel(let message):
            return "Invalid SDEF model: \(message)"
        }
    }
}