//
// AppLocator.swift
// SwiftScriptingBridge
//
// Created by Rene Hexel on 28/6/2025.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
public import ScriptingBridge
import Foundation

/// Locate an application by name and type.
///
/// This function searches for an application with the given name and type
/// in the default locations. If the application is found, it is returned.
/// Otherwise, `nil` is returned.
///
/// - Parameters:
///   - appName: The name of the application.
///   - type: The type of the application.
///   - inLocations: The locations to search for the application.
/// - Returns: The application, or `nil` if it could not be found.
@inlinable
public func findApp<T: SBApplicationProtocol>(named appName: String, inLocations: [URL] = defaultAppLocations) -> T? {
    let fm = FileManager.default
    let hasAppSuffix = appName.hasSuffix(".app")
    for location in inLocations {
        guard let appURL = URL(string: appName, relativeTo: location) else { continue }
        if let app = app(at: appURL, ofType: T.self) { return app }
        if !hasAppSuffix,
           let app = app(at: appURL.appendingPathExtension("app"), ofType: T.self) {
            return app
        }
        guard let enumerator = fm.enumerator(atPath: location.path) else { continue }
        while let name = enumerator.nextObject() as? String {
            if name.hasSuffix(".app") || enumerator.level > 2 {
                enumerator.skipDescendants()
            }
            guard let url = URL(string: name, relativeTo: location) else { continue }
            var isDirObjCBool: ObjCBool = false
            guard url.lastPathComponent == appName || url.lastPathComponent == appName + ".app" else {
                guard let appURL = URL(string: appName, relativeTo: url) else { continue }
                guard fm.fileExists(atPath: appURL.path, isDirectory: &isDirObjCBool), isDirObjCBool.boolValue else { continue }
                if let app = app(at: appURL, ofType: T.self) {
                    return app
                }
                continue
            }
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirObjCBool), isDirObjCBool.boolValue else { continue }
            if let app = app(at: url, ofType: T.self) {
                return app
            }
        }
    }
    return nil
}

/// Return a typed `SBApplication` for the given URL and type.
///
/// This function returns an `SBApplication` for the given path.
/// The returned application is strongly typed, so it has the relevant
/// methods and properties available that were defined in the application's
/// scripting definition.
///
/// - Parameters:
///   - url: The file url of the application.
///   - type: The type of the application.
/// - Returns: The application, or `nil` if it could not be found.
@inlinable
public func app<T: SBApplicationProtocol>(at url: URL, ofType type: T.Type = T.self) -> T? {
    guard let bundle = Bundle(url: url),
          let identifier = bundle.bundleIdentifier,
          let app = app(withIdentifier: identifier, ofType: T.self) else { return nil }

    return app
}

/// Return a typed `SBApplication` for the given bundle identifier and type.
///
/// This function returns an `SBApplication` for the given bundle identifier.
/// The returned application is strongly typed, so it has the relevant
/// methods and properties available that were defined in the application's
/// scripting definition.
///
/// - Parameters:
///   - bundleIdentifier: The bundle identifier of the application.
///   - type: The type of the application.
/// - Returns: The application, or `nil` if it could not be found.
@inlinable
public func app<T: SBApplicationProtocol>(withIdentifier bundleIdentifier: String, ofType type: T.Type = T.self) -> T? {
    return SBApplication(bundleIdentifier: bundleIdentifier) as? T
}

/// List of default application locations.
///
/// These locations are searched when looking for applications.
public let defaultAppLocations: [URL] = [
    URL(filePath: "/Applications", directoryHint: .isDirectory),
    URL(filePath: "/Applications/Utilities", directoryHint: .isDirectory),
    URL(filePath: "/System/Library/CoreServices", directoryHint: .isDirectory),
    URL(filePath: "/System/Applications", directoryHint: .isDirectory),
    URL(filePath: "/System/Applications/Utilities", directoryHint: .isDirectory)
]
