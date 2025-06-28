//
// SDEFTests.swift
// SDEFTests
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import SDEF

/// Tests for the SDEF library functionality.
///
/// This test suite validates the core functionality of the SDEF library, including
/// parsing of SDEF XML documents, model creation, and Swift code generation.
/// The tests use sample SDEF data to verify that the library correctly handles
/// various SDEF structures and produces expected Swift output.
struct SDEFTests {

    /// Tests basic SDEF model creation with simple data.
    ///
    /// This test verifies that the fundamental SDEF model structures can be created
    /// and that their properties are correctly stored and accessible. It validates
    /// the basic building blocks of the SDEF system without requiring XML parsing.
    @Test func testSDEFModelCreation() throws {
        let property = SDEFProperty(
            name: "test property",
            code: "test",
            type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true),
            description: "A test property",
            access: "r",
            isHidden: false
        )

        let sdefClass = SDEFClass(
            name: "test class",
            pluralName: "test classes",
            code: "tcls",
            description: "A test class",
            inherits: nil,
            properties: [property],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Test Suite",
            code: "test",
            description: "A test suite",
            classes: [sdefClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])

        #expect(model.suites.count == 1)
        #expect(model.suites.first?.name == "Test Suite")
        #expect(model.suites.first?.classes.count == 1)
        #expect(model.suites.first?.classes.first?.name == "test class")
        #expect(model.suites.first?.classes.first?.properties.count == 1)
        #expect(model.suites.first?.classes.first?.properties.first?.name == "test property")
    }

    /// Tests SDEF enumeration model creation.
    ///
    /// This test validates that enumeration structures are correctly created and
    /// that their enumerators are properly stored with all necessary metadata
    /// including codes, descriptions, and string values.
    @Test func testSDEFEnumerationCreation() throws {
        let enumerator1 = SDEFEnumerator(
            name: "first",
            code: "fst1",
            description: "The first option",
            stringValue: "first_value"
        )

        let enumerator2 = SDEFEnumerator(
            name: "second",
            code: "scd2",
            description: "The second option",
            stringValue: nil
        )

        let enumeration = SDEFEnumeration(
            name: "test enumeration",
            code: "enum",
            description: "A test enumeration",
            enumerators: [enumerator1, enumerator2],
            isHidden: false
        )

        #expect(enumeration.name == "test enumeration")
        #expect(enumeration.enumerators.count == 2)
        #expect(enumeration.enumerators[0].name == "first")
        #expect(enumeration.enumerators[0].stringValue == "first_value")
        #expect(enumeration.enumerators[1].name == "second")
        #expect(enumeration.enumerators[1].stringValue == nil)
    }

    /// Tests basic XML parsing functionality.
    ///
    /// This test verifies that the SDEF parser can correctly process simple XML
    /// structures and extract basic suite and class information. It uses a minimal
    /// SDEF XML document to validate the core parsing logic.
    @Test func testBasicXMLParsing() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <dictionary>
            <suite name="Test Suite" code="test" description="A test suite">
                <class name="test class" code="tcls" description="A test class">
                    <property name="test property" code="tprop" type="text" description="A test property" access="r"/>
                </class>
            </suite>
        </dictionary>
        """

        let xmlData = xmlString.data(using: .utf8)!
        let xmlDocument = try XMLDocument(data: xmlData, options: [])

        let parser = SDEFParser(document: xmlDocument, includeHidden: false, verbose: false)
        let model = try parser.parse()

        #expect(model.suites.count == 1)

        let suite = model.suites.first!
        #expect(suite.name == "Test Suite")
        #expect(suite.code == "test")
        #expect(suite.description == "A test suite")
        #expect(suite.classes.count == 1)

        let testClass = suite.classes.first!
        #expect(testClass.name == "test class")
        #expect(testClass.code == "tcls")
        #expect(testClass.description == "A test class")
        #expect(testClass.properties.count == 1)

        let property = testClass.properties.first!
        #expect(property.name == "test property")
        #expect(property.code == "tprop")
        #expect(property.type.baseType == "text")
        #expect(property.access == "r")
    }

    /// Tests Swift code generation from a simple model.
    ///
    /// This test validates that the Swift code generator can produce syntactically
    /// correct Swift code from SDEF model data. It checks that the generated code
    /// includes the expected protocols, type aliases, and method signatures.
    @Test func testBasicSwiftCodeGeneration() throws {
        let property = SDEFProperty(
            name: "name",
            code: "pnam",
            type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true),
            description: "The name property",
            access: "r",
            isHidden: false
        )

        let testClass = SDEFClass(
            name: "window",
            pluralName: "windows",
            code: "cwin",
            description: "A window",
            inherits: nil,
            properties: [property],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Test Suite",
            code: "test",
            description: "A test suite",
            classes: [testClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Test", verbose: false)
        let swiftCode = try generator.generateCode()

        // Verify basic structure
        #expect(swiftCode.contains("import Foundation"))
        #expect(swiftCode.contains("import ScriptingBridge"))
        #expect(swiftCode.contains("public typealias TestApplication = SBApplication"))
        #expect(swiftCode.contains("@objc public protocol TestWindow:"))
        #expect(swiftCode.contains("/// The name property"))
        #expect(swiftCode.contains("@objc optional var name: String?"))
        #expect(swiftCode.contains("extension SBObject: TestWindow"))
    }

    /// Tests the SDEF convenience API functionality.
    ///
    /// This test validates the high-level convenience methods provided by the SDEF
    /// enum, ensuring they correctly coordinate parsing and code generation without
    /// requiring direct instantiation of parser and generator classes.
    @Test func testSDEFConvenienceAPI() throws {
        let xmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <dictionary>
            <suite name="Test Suite" code="test">
                <class name="document" code="docu">
                    <property name="name" code="pnam" type="text" access="r"/>
                </class>
            </suite>
        </dictionary>
        """

        let xmlData = xmlString.data(using: .utf8)!
        let xmlDocument = try XMLDocument(data: xmlData, options: [])

        // Test parser convenience method
        let parser = SDEF.parser(for: xmlDocument, includeHidden: false, verbose: false)
        let model = try parser.parse()

        #expect(model.suites.count == 1)
        #expect(model.suites.first?.classes.count == 1)

        // Test generator convenience method
        let generator = SDEF.swiftGenerator(for: model, basename: "Test", verbose: false)
        let swiftCode = try generator.generateCode()

        #expect(swiftCode.contains("TestDocument"))
        #expect(swiftCode.contains("@objc optional var name: String?"))
    }

    /// Tests error handling for invalid XML input.
    ///
    /// This test ensures that the parser properly handles malformed XML and provides
    /// appropriate error messages when encountereding invalid SDEF structures or
    /// missing required elements.
    @Test func testInvalidXMLHandling() throws {
        let invalidXMLString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <dictionary>
            <suite name="Test Suite">
                <class name="test class">
                    <property name="test property" invalid_attribute="value"/>
                </class>
            </suite>
        </dictionary>
        """

        let xmlData = invalidXMLString.data(using: .utf8)!
        let xmlDocument = try XMLDocument(data: xmlData, options: [])

        let parser = SDEFParser(document: xmlDocument, includeHidden: false, verbose: false)

        // The parser should handle missing attributes gracefully
        let model = try parser.parse()
        #expect(model.suites.count == 1)

        // Properties with missing codes should get empty strings
        let property = model.suites.first?.classes.first?.properties.first
        #expect(property?.code == "")
    }
}
