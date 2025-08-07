//
// DefaultSearchPaths.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Default search paths for locating .sdef files and applications
public struct DefaultSearchPaths {
    /// Standard macOS directories to search for applications and .sdef files
    public static let paths: [String] = [
        ".",
        "/Applications",
        "/Applications/Utilities",
        "/System/Applications",
        "/System/Applications/Utilities",
        "/System/Library/CoreServices",
        "/Library/CoreServices"
    ]

    /// Get the default search paths, filtering out non-existent directories
    public static func getExistingPaths() -> [String] {
        paths.filter { FileManager.default.fileExists(atPath: $0) }
    }

    /// Find an application by bundle identifier in the search paths
    /// - Parameter bundleIdentifier: The bundle identifier to search for
    /// - Returns: The path to the application if found, nil otherwise
    public static func findApplication(bundleIdentifier: String) -> String? {
        let fileManager = FileManager.default

        for searchPath in getExistingPaths() {
            // Check direct .app bundles in the search path
            if let contents = try? fileManager.contentsOfDirectory(atPath: searchPath) {
                for item in contents where item.hasSuffix(".app") {
                    let appPath = "\(searchPath)/\(item)"
                    let plistPath = "\(appPath)/Contents/Info.plist"

                    if fileManager.fileExists(atPath: plistPath),
                       let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
                       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
                       let appBundleId = plist["CFBundleIdentifier"] as? String,
                       appBundleId == bundleIdentifier {
                        return appPath
                    }
                }
            }
        }

        return nil
    }

}
