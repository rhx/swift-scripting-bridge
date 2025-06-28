//
//  ObjectInstantiator.swift
//  ScriptingBridge
//
// Created by Rene Hexel on 28/6/2025.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation
public import ScriptingBridge

/// Instantiate an app object.
///
/// This function creates an instance of an app object using the provided name and type.
/// It returns an instance of the specified object type or nil if the object could not be created.
///
/// - Parameters:
///   - name: The name of the object to instantiate.
///   - type: The type of the object to instantiate. Defaults to the specified object type.
///   - app: The app in which to instantiate the object.
///   - properties: Additional properties to set on the object. Defaults to an empty dictionary.
///
/// - Returns: An instance of the specified object type or nil if the object could not be created.
@inlinable
public func appObject<App: SBApplicationProtocol, Object: SBObjectProtocol>(named name: String, ofType type: Object.Type = Object.self, in app: App, properties: [AnyHashable: Any] = [:]) -> Object! {
    guard let appClass = (app as? SBApplication)?.class(forScriptingClass: name) as? SBObject.Type else { return nil }
    return appClass.init(properties: properties) as? Object
}

/// Instantiate an app object using a class name enum case.
///
/// This function creates an instance of an app object using the provided class name and type.
/// It returns an instance of the specified object type or nil if the object could not be created.
///
/// - Parameters:
///   - name: The class name enum case of the object to instantiate.
///   - type: The type of the object to instantiate. Defaults to the specified object type.
///   - app: The app in which to instantiate the object.
///   - properties: Additional properties to set on the object. Defaults to an empty dictionary.
///
/// - Returns: An instance of the specified object type or nil if the object could not be created.
@inlinable
public func appObject<SBName: RawRepresentable, App: SBApplicationProtocol, Object: SBObjectProtocol>(className name: SBName, ofType type: Object.Type = Object.self, in app: App, properties: [AnyHashable: Any] = [:]) -> Object! where SBName.RawValue == String {
    appObject(named: name.rawValue, ofType: type, in: app, properties: properties)
}
