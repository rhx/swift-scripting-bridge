//
// SwiftScriptingBridge.swift
// SwiftScriptingBridge
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
public import ScriptingBridge

/// Protocol for ScritingBridge Objects.
///
/// This protocol defines the basic functionality for ScriptingBridge objects.
@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}
extension SBObject: SBObjectProtocol {}

/// Protocol for ScriptingBridge Applications.
///
/// This protocol defines the basic functionality for ScriptingBridge applications.
@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var isRunning: Bool { get }
}
extension SBApplication: SBApplicationProtocol {}
