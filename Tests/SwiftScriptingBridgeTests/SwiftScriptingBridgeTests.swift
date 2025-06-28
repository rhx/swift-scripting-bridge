//
// SwiftScriptingBridgeTests.swift
// SwiftScriptingBridge
//
// Created by Rene Hexel on 28/6/2025.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

import Testing
import Foundation
import ScriptingBridge
@testable import SwiftScriptingBridge

// MARK: - Test Implementations

/// Test implementation of SBApplicationProtocol for testing purposes
final class TestApplication: NSObject, SBApplicationProtocol {
    var mockIsRunning: Bool = false
    var mockDelegate: SBApplicationDelegate?
    let bundleId: String

    init(bundleIdentifier: String) {
        self.bundleId = bundleIdentifier
        super.init()
    }

    var isRunning: Bool {
        return mockIsRunning
    }

    var delegate: SBApplicationDelegate! {
        get { mockDelegate }
        set { mockDelegate = newValue }
    }

    func activate() {
        // Mock implementation
    }

    func get() -> Any! {
        return "test-app-\(bundleId)"
    }
}

/// Test implementation of SBObjectProtocol for testing purposes
final class TestObject: NSObject, SBObjectProtocol {
    private let identifier: String

    init(identifier: String = "test-object") {
        self.identifier = identifier
        super.init()
    }

    func get() -> Any! {
        return identifier
    }
}

// MARK: - AppLocator Tests

@Suite("AppLocator Tests")
struct AppLocatorTests {

    @Test("Default app locations should contain standard macOS directories")
    func testDefaultAppLocations() {
        let locations = defaultAppLocations

        #expect(locations.count == 3)
        #expect(locations.contains { $0.path == "/Applications" })
        #expect(locations.contains { $0.path == "/System/Library/CoreServices" })
        #expect(locations.contains { $0.path == "/System/Applications" })
    }

    @Test("App creation with bundle identifier")
    func testAppWithBundleIdentifier() {
        // Test with TestApplication (which conforms to SBApplicationProtocol)
        let testApp: TestApplication? = app(withIdentifier: "com.test.app")

        // This will return nil because SBApplication(bundleIdentifier:) creates SBApplication,
        // not TestApplication, so the cast fails
        #expect(testApp == nil)

        // But we can test that the function doesn't crash
        let _: TestApplication? = app(withIdentifier: "")
        let _: TestApplication? = app(withIdentifier: "invalid.bundle.id")
    }

    @Test("App creation with real SBApplication")
    func testRealSBApplicationCreation() {
        // Test the underlying SBApplication creation
        let finderApp = SBApplication(bundleIdentifier: "com.apple.finder")
        #expect(finderApp != nil)

        // Test that we can find Finder by name
        let namedFinder: SBApplication? = findApp(named: "Finder")
        #expect(namedFinder != nil)
        #expect(namedFinder == finderApp)

        // Test that Finder is running
        let isRunning = namedFinder?.isRunning ?? false
        #expect(isRunning)

        let invalidApp = SBApplication(bundleIdentifier: "com.invalid.app")
        // SBApplication may return nil for truly invalid bundle identifiers
        _ = invalidApp

        let emptyApp = SBApplication(bundleIdentifier: "")
        // SBApplication may return nil for empty bundle identifier
        _ = emptyApp
    }

    @Test("App at URL functionality")
    func testAppAtURL() {
        // Test with non-existent URL
        let invalidURL = URL(filePath: "/NonExistent/Path/App.app")
        let testApp: TestApplication? = app(at: invalidURL)
        #expect(testApp == nil)

        // Test with empty URL
        let emptyURL = URL(filePath: "")
        let testApp2: TestApplication? = app(at: emptyURL)
        #expect(testApp2 == nil)
    }

    @Test("Find app functionality")
    func testFindApp() {
        // Test with empty locations
        let app1: TestApplication? = findApp(named: "TestApp", inLocations: [])
        #expect(app1 == nil)

        // Test with non-existent locations
        let nonExistentLocations = [
            URL(filePath: "/NonExistent/Directory1"),
            URL(filePath: "/NonExistent/Directory2")
        ]
        let app2: TestApplication? = findApp(named: "TestApp", inLocations: nonExistentLocations)
        #expect(app2 == nil)

        // Test with default locations (should not crash)
        let app3: TestApplication? = findApp(named: "NonExistentApp")
        #expect(app3 == nil)
    }
}

// MARK: - ObjectInstantiator Tests

@Suite("ObjectInstantiator Tests")
struct ObjectInstantiatorTests {

    @Test("App object creation with string name")
    func testAppObjectWithStringName() {
        let testApp = TestApplication(bundleIdentifier: "com.test.app")

        // Test object creation - will return nil because TestApplication doesn't implement
        // the scripting class lookup that a real SBApplication would have
        let object: TestObject? = appObject(named: "document", in: testApp)
        #expect(object == nil)

        // Test with empty name
        let emptyObject: TestObject? = appObject(named: "", in: testApp)
        #expect(emptyObject == nil)
    }

    @Test("App object creation with enum name")
    func testAppObjectWithEnumName() {
        enum ScriptingClass: String {
            case document = "document"
            case window = "window"
        }

        let testApp = TestApplication(bundleIdentifier: "com.test.app")

        let object: TestObject? = appObject(className: ScriptingClass.document, in: testApp)
        #expect(object == nil)

        let windowObject: TestObject? = appObject(className: ScriptingClass.window, in: testApp)
        #expect(windowObject == nil)
    }

    @Test("App object creation with properties")
    func testAppObjectWithProperties() {
        let testApp = TestApplication(bundleIdentifier: "com.test.app")
        let properties: [AnyHashable: Any] = [
            "name": "Test Document",
            "visible": true,
            "count": 42
        ]

        let object: TestObject? = appObject(named: "document", in: testApp, properties: properties)
        #expect(object == nil)

        // Test with empty properties
        let emptyPropsObject: TestObject? = appObject(named: "document", in: testApp, properties: [:])
        #expect(emptyPropsObject == nil)
    }

    @Test("Function signatures compile correctly")
    func testFunctionSignatures() {
        let testApp = TestApplication(bundleIdentifier: "com.test.app")

        // Test that all function signatures compile without explicit type parameters
        let _: TestObject? = appObject(named: "test", in: testApp)
        let _: TestObject? = appObject(named: "test", in: testApp, properties: [:])

        enum TestEnum: String {
            case test = "test"
        }
        let _: TestObject? = appObject(className: TestEnum.test, in: testApp)
        let _: TestObject? = appObject(className: TestEnum.test, in: testApp, properties: [:])
    }
}

// MARK: - Protocol Tests

@Suite("Protocol Tests")
struct ProtocolTests {

    @Test("SBObjectProtocol conformance")
    func testSBObjectProtocolConformance() {
        let testObject = TestObject(identifier: "test-123")

        // Test the get method
        let result = testObject.get()
        #expect(result as? String == "test-123")
    }

    @Test("SBApplicationProtocol conformance")
    func testSBApplicationProtocolConformance() {
        let testApp = TestApplication(bundleIdentifier: "com.test.app")

        // Test properties
        testApp.mockIsRunning = true
        #expect(testApp.isRunning == true)

        testApp.mockIsRunning = false
        #expect(testApp.isRunning == false)

        // Test delegate property
        #expect(testApp.delegate == nil)

        // Test methods
        testApp.activate() // Should not crash

        let result = testApp.get()
        #expect(result as? String == "test-app-com.test.app")
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("Real SBApplication functionality")
    func testRealSBApplicationFunctionality() {
        // Test with actual SBApplication (not our protocol-conforming version)
        let finderApp = SBApplication(bundleIdentifier: "com.apple.finder")

        #expect(finderApp != nil)

        // Test basic properties that should be available
        let isRunning = finderApp?.isRunning ?? false
        #expect(isRunning)

        // Test get method
        let result = finderApp?.get()
        // Result may be nil for some applications, just test that method can be called
        _ = result

        // Test that we can access delegate property
        let delegate = finderApp?.delegate
        _ = delegate // May be nil, that's fine
    }

    @Test("App location verification")
    func testAppLocationVerification() {
        let fm = FileManager.default

        // Verify that at least one of the default locations exists
        let existingLocations = defaultAppLocations.filter { location in
            var isDirectory: ObjCBool = false
            return fm.fileExists(atPath: location.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }

        #expect(existingLocations.count > 0, "At least one default app location should exist")

        // Test that each existing location is readable
        for location in existingLocations {
            #expect(fm.isReadableFile(atPath: location.path), "Location \(location.path) should be readable")
        }
    }

    @Test("Complete workflow simulation")
    func testCompleteWorkflowSimulation() {
        // Test the complete workflow with our test implementations
        let testApp = TestApplication(bundleIdentifier: "com.test.workflow")
        testApp.mockIsRunning = true

        // Test that we can use the app
        #expect(testApp.isRunning)
        testApp.activate()

        let appResult = testApp.get()
        #expect(appResult as? String == "test-app-com.test.workflow")

        // Test object creation
        let obj: TestObject? = appObject(named: "nonexistent", in: testApp)
        #expect(obj == nil) // Expected because TestApplication doesn't implement scripting class lookup
    }
}

// MARK: - Edge Cases and Error Handling

@Suite("Edge Cases and Error Handling")
struct EdgeCaseTests {

    @Test("URL edge cases")
    func testURLEdgeCases() {
        // Test various edge case URLs
        let testCases = [
            URL(filePath: ""),
            URL(filePath: "/"),
            URL(filePath: "/Applications"),
            URL(filePath: "/NonExistent/Path/App.app"),
            URL(filePath: "/tmp")
        ]

        for url in testCases {
            let app: TestApplication? = app(at: url)
            // Should not crash, may return nil
            _ = app
        }
    }

    @Test("String parameter edge cases")
    func testStringParameterEdgeCases() {
        let testApp = TestApplication(bundleIdentifier: "com.test.edge")

        let edgeCaseNames = [
            "",
            " ",
            "test-name",
            "test_name",
            "test.name",
            "test name",
            "test@name",
            "тест", // Cyrillic
            "테스트", // Korean
            "🧪",   // Emoji
            String(repeating: "a", count: 1000) // Long string
        ]

        for name in edgeCaseNames {
            let obj: TestObject? = appObject(named: name, in: testApp)
            // Should not crash
            _ = obj
        }
    }

    @Test("Large properties dictionary")
    func testLargePropertiesDictionary() {
        let testApp = TestApplication(bundleIdentifier: "com.test.large")

        // Create a large properties dictionary
        var largeProperties: [AnyHashable: Any] = [:]
        for i in 0..<10000 {
            largeProperties["key\(i)"] = "value\(i)"
            largeProperties[i] = "numeric_key_\(i)"
        }

        // Should not crash with large properties
        let obj: TestObject? = appObject(named: "test", in: testApp, properties: largeProperties)
        _ = obj
    }

    @Test("Memory management")
    func testMemoryManagement() {
        weak var weakApp: TestApplication?
        weak var weakObject: TestObject?

        do {
            let app = TestApplication(bundleIdentifier: "com.test.memory")
            let object = TestObject(identifier: "memory-test")

            weakApp = app
            weakObject = object

            #expect(weakApp != nil)
            #expect(weakObject != nil)

            // Use the objects
            app.activate()
            _ = object.get()
        }

        // Objects should be deallocated after leaving scope
        #expect(weakApp == nil)
        #expect(weakObject == nil)
    }

    @Test("Concurrent access")
    func testConcurrentAccess() async {
        // Test that multiple apps can be created concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let testApp = TestApplication(bundleIdentifier: "com.test.concurrent\(i)")
                    let obj: TestObject? = appObject(named: "object\(i)", in: testApp)
                    _ = obj
                    testApp.activate()
                    _ = testApp.get()
                }
            }
        }

        // Test completed without crashing
        #expect(Bool(true))
    }
}

// MARK: - Performance Tests

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("App location enumeration performance", .timeLimit(.minutes(1)))
    func testAppLocationEnumerationPerformance() {
        // Test that location enumeration completes in reasonable time
        let locations = defaultAppLocations

        for location in locations {
            let fm = FileManager.default
            guard let enumerator = fm.enumerator(atPath: location.path) else { continue }

            var count = 0
            while let _ = enumerator.nextObject(), count < 100 { // Limit to avoid excessive test time
                count += 1
            }
        }

        #expect(locations.count == 3)
    }

    @Test("Multiple app creation performance", .timeLimit(.minutes(1)))
    func testMultipleAppCreationPerformance() {
        // Test creating multiple apps quickly
        for i in 0..<1000 {
            let app = TestApplication(bundleIdentifier: "com.test.perf\(i)")
            _ = app.get()
        }
    }
}

// MARK: - Functional Tests

@Suite("Functional Tests")
struct FunctionalTests {

    @Test("Default locations are properly formed URLs")
    func testDefaultLocationsURLs() {
        for location in defaultAppLocations {
            #expect(location.path.hasPrefix("/"))
            #expect(!location.path.isEmpty)
            #expect(location.isFileURL)
        }
    }

    @Test("Bundle identifier validation")
    func testBundleIdentifierValidation() {
        let validIdentifiers = [
            "com.apple.finder",
            "com.test.app",
            "org.example.application",
            "a.b.c"
        ]

        let invalidIdentifiers = [
            "",
            " ",
            "invalid",
            ".com.test",
            "com.test."
        ]

        // Test that all identifiers can be used to create apps (even invalid ones)
        for identifier in validIdentifiers + invalidIdentifiers {
            let app = TestApplication(bundleIdentifier: identifier)
            #expect(app.bundleId == identifier)
        }
    }

    @Test("Property types handling")
    func testPropertyTypesHandling() {
        let testApp = TestApplication(bundleIdentifier: "com.test.properties")

        let mixedProperties: [AnyHashable: Any] = [
            "string": "test",
            "int": 42,
            "double": 3.14,
            "bool": true,
            "array": [1, 2, 3],
            "dict": ["nested": "value"],
            "nil": NSNull(),
            "date": Date(),
            "url": URL(string: "https://example.com")!
        ]

        // Should handle various property types without crashing
        let obj: TestObject? = appObject(named: "test", in: testApp, properties: mixedProperties)
        _ = obj
    }
}

// MARK: - Helper Extensions for Testing



// MARK: - Error Types for Testing

enum TestError: Error, CustomStringConvertible {
    case skipTest(String)
    case testFailure(String)

    var description: String {
        switch self {
        case .skipTest(let reason):
            return "Test skipped: \(reason)"
        case .testFailure(let reason):
            return "Test failed: \(reason)"
        }
    }
}
