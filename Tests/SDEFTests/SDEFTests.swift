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
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Test", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: false, verbose: false)
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
        let parser = SDEFLibrary.parser(for: xmlDocument, includeHidden: false, verbose: false)
        let model = try parser.parse()

        #expect(model.suites.count == 1)
        #expect(model.suites.first?.classes.count == 1)

        // Test generator convenience method
        let generator = SDEFLibrary.swiftGenerator(for: model, basename: "Test", verbose: false)
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

    /// Tests that element array method names are properly camelCased.
    ///
    /// This test validates that when generating protocol methods for accessing
    /// element arrays, the method names are properly converted to camelCase,
    /// especially for multi-word class names with spaces.
    @Test func testElementArrayMethodCamelCasing() throws {
        // Create a class with multi-word name and plural
        let audioCDTrackClass = SDEFClass(
            name: "audio CD track",
            pluralName: "audio CD tracks",
            code: "cCDT",
            description: "a track on an audio CD",
            inherits: "track",
            properties: [],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        // Create a container class that has audio CD tracks as elements
        let element = SDEFElement(type: "audio CD track", cocoaKey: nil)
        let containerClass = SDEFClass(
            name: "CD",
            pluralName: "CDs",
            code: "cCD ",
            description: "a CD",
            inherits: nil,
            properties: [],
            elements: [element],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Test Suite",
            code: "test",
            description: "A test suite",
            classes: [audioCDTrackClass, containerClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Test", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: false, verbose: false)
        let swiftCode = try generator.generateCode()

        // Verify that the generated method name is properly camelCased
        #expect(swiftCode.contains("@objc optional func audioCDTracks() -> SBElementArray"))

        // Verify it doesn't contain the improperly spaced version
        #expect(!swiftCode.lowercased().contains("func audio cd tracks"))
    }

    /// Tests that setter methods have proper DocC comments and capitalization.
    ///
    /// This test validates that when generating setter methods for writable properties,
    /// the setter methods include properly formatted DocC comments that start with
    /// "Set" and have proper capitalization, and that all DocC comments start with
    /// a capital letter. Also verifies that enumeration and class descriptions are
    /// properly capitalized.
    @Test func testSetterDocCCommentsAndCapitalization() throws {
        // Create a property with a description
        let artistProperty = SDEFProperty(
            name: "artist",
            code: "pArt",
            type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true),
            description: "the artist of the CD",
            access: "",  // Not read-only, so setter will be generated
            isHidden: false
        )

        // Create a read-only property to verify no setter is generated
        let readOnlyProperty = SDEFProperty(
            name: "duration",
            code: "pDur",
            type: SDEFPropertyType(baseType: "integer", isList: false, isOptional: true),
            description: "the duration of the track",
            access: "r",  // Read-only
            isHidden: false
        )

        // Create an enumeration with description
        let testEnumeration = SDEFEnumeration(
            name: "format",
            code: "fmt ",
            description: "the audio format",
            enumerators: [
                SDEFEnumerator(
                    name: "MP3",
                    code: "mp3 ",
                    description: "MP3 audio format",
                    stringValue: nil
                )
            ],
            isHidden: false
        )

        let testClass = SDEFClass(
            name: "CD",
            pluralName: "CDs",
            code: "cCD ",
            description: "a compact disc",
            inherits: nil,
            properties: [artistProperty, readOnlyProperty],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Test Suite",
            code: "test",
            description: "A test suite",
            classes: [testClass],
            enumerations: [testEnumeration],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Test", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: false, verbose: false)
        let swiftCode = try generator.generateCode()

        // Verify property DocC comment is properly capitalized
        #expect(swiftCode.contains("/// The artist of the CD"))

        // Verify read-only property DocC comment is properly capitalized
        #expect(swiftCode.contains("/// The duration of the track"))

        // Verify setter DocC comment exists and is properly formatted
        #expect(swiftCode.contains("/// Set the artist of the CD"))

        // Verify setter method exists
        #expect(swiftCode.contains("@objc optional func setArtist(_ artist: String?)"))

        // Verify no setter is generated for read-only property
        #expect(!swiftCode.contains("setDuration"))

        // Verify class description is properly capitalized
        #expect(swiftCode.contains("/// A compact disc"))

        // Verify enumeration description is properly capitalized
        #expect(swiftCode.contains("/// The audio format"))

        // Verify enumerator description is properly capitalized
        #expect(swiftCode.contains("/// MP3 audio format"))

        // Verify original lowercase descriptions are not present
        #expect(!swiftCode.contains("/// the artist of the CD"))
        #expect(!swiftCode.contains("/// the duration of the track"))
        #expect(!swiftCode.contains("/// a compact disc"))
        #expect(!swiftCode.contains("/// the audio format"))
    }

    /// Tests a comprehensive example showing both camelCase and DocC comment fixes.
    ///
    /// This test demonstrates the complete solution for the reported issues:
    /// - Element array methods are properly camelCased (e.g., audioCDTracks())
    /// - Setter methods have proper DocC comments starting with "Set"
    /// - All DocC comments start with capital letters
    @Test func testComprehensiveExample() throws {
        // Create the "audio CD track" class as mentioned in the issue
        let audioCDTrackClass = SDEFClass(
            name: "audio CD track",
            pluralName: "audio CD tracks",
            code: "cCDT",
            description: "a track on an audio CD",
            inherits: "track",
            properties: [
                SDEFProperty(
                    name: "artist",
                    code: "pArt",
                    type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true),
                    description: "the artist of the CD",
                    access: "",
                    isHidden: false
                )
            ],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        // Create a container class that has audio CD tracks as elements
        let cdClass = SDEFClass(
            name: "compact disc",
            pluralName: "compact discs",
            code: "cCD ",
            description: "a compact disc",
            inherits: nil,
            properties: [],
            elements: [SDEFElement(type: "audio CD track", cocoaKey: nil)],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Audio Suite",
            code: "audi",
            description: "audio management suite",
            classes: [audioCDTrackClass, cdClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Audio", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: false, verbose: false)
        let swiftCode = try generator.generateCode()

        // Verify the main issue is fixed: element array method is properly camelCased
        #expect(swiftCode.contains("@objc optional func audioCDTracks() -> SBElementArray"))
        #expect(!swiftCode.contains("audio cd tracks()"))

        // Verify setter has proper DocC comment
        #expect(swiftCode.contains("/// Set the artist of the CD"))
        #expect(swiftCode.contains("@objc optional func setArtist(_ artist: String?)"))

        // Verify all DocC comments are properly capitalized
        #expect(swiftCode.contains("/// A track on an audio CD"))
        #expect(swiftCode.contains("/// A compact disc"))
        #expect(swiftCode.contains("/// The artist of the CD"))

        // Verify original lowercase descriptions are not present
        #expect(!swiftCode.contains("/// a track on an audio CD"))
        #expect(!swiftCode.contains("/// a compact disc"))
        #expect(!swiftCode.contains("/// the artist of the CD"))
    }

    /// Tests protocol name capitalization for multi-word class names.
    ///
    /// This test verifies that class names with multiple words are properly
    /// converted to PascalCase for protocol names, fixing issues where names
    /// like "radio tuner playlist" became "MusicRadiotunerplaylist" instead
    /// of the correct "MusicRadioTunerPlaylist".
    @Test func testProtocolNameCapitalization() throws {
        let radioTunerPlaylistClass = SDEFClass(
            name: "radio tuner playlist",
            pluralName: "radio tuner playlists",
            code: "cRTP",
            description: "the radio tuner playlist",
            inherits: "playlist",
            properties: [],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        let urlTrackClass = SDEFClass(
            name: "URL track",
            pluralName: "URL tracks",
            code: "cURT",
            description: "a track representing a network stream",
            inherits: "track",
            properties: [],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Music Suite",
            code: "musi",
            description: "Music application suite",
            classes: [radioTunerPlaylistClass, urlTrackClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Music", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: false, verbose: false)
        let swiftCode = try generator.generateCode()

        // Verify correct protocol name capitalization
        #expect(swiftCode.contains("@objc public protocol MusicRadioTunerPlaylist:"))
        #expect(swiftCode.contains("@objc public protocol MusicURLTrack:"))

        // Verify incorrect capitalization is not present
        #expect(!swiftCode.contains("MusicRadiotunerplaylist"))
        #expect(!swiftCode.contains("MusicUrltrack"))
    }

    /// Tests strongly typed extension generation.
    ///
    /// This test verifies that when the shouldGenerateStronglyTypedExtensions
    /// flag is enabled, the generator creates protocol extensions with strongly
    /// typed accessor properties that cast SBElementArray to specific types.
    @Test func testStronglyTypedExtensions() throws {
        // Create URL track class
        let urlTrackClass = SDEFClass(
            name: "URL track",
            pluralName: "URL tracks",
            code: "cURT",
            description: "a track representing a network stream",
            inherits: "track",
            properties: [],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        // Create playlist class that contains URL tracks
        let playlistClass = SDEFClass(
            name: "radio tuner playlist",
            pluralName: "radio tuner playlists",
            code: "cRTP",
            description: "the radio tuner playlist",
            inherits: "playlist",
            properties: [],
            elements: [SDEFElement(type: "URL track", cocoaKey: nil)],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Music Suite",
            code: "musi",
            description: "Music application suite",
            classes: [urlTrackClass, playlistClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Music", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: true, verbose: false)
        let swiftCode = try generator.generateCode()



        // Verify the protocol method exists
        #expect(swiftCode.contains("@objc optional func URLTracks() -> SBElementArray"))

        // Verify strongly typed extension is generated
        #expect(swiftCode.contains("/// Strongly typed accessors for radio tuner playlist"))
        #expect(swiftCode.contains("public extension MusicRadioTunerPlaylist {"))
        #expect(swiftCode.contains("/// Strongly typed accessor for URL track elements"))
        #expect(swiftCode.contains("var musicURLTracks: [MusicURLTrack] {"))
        #expect(swiftCode.contains("URLTracks?() as? [MusicURLTrack] ?? []"))

        // Verify correct property naming
        #expect(swiftCode.contains("var musicURLTracks: [MusicURLTrack]"))
        #expect(!swiftCode.contains("var urlTracks: [MusicURLTrack]"))
    }

    /// Tests that strongly typed extensions are not generated when disabled.
    ///
    /// This test ensures that when shouldGenerateStronglyTypedExtensions is false,
    /// no strongly typed extension code is generated.
    @Test func testStronglyTypedExtensionsDisabled() throws {
        let playlistClass = SDEFClass(
            name: "playlist",
            pluralName: "playlists",
            code: "cPls",
            description: "a playlist",
            inherits: nil,
            properties: [],
            elements: [SDEFElement(type: "track", cocoaKey: nil)],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Music Suite",
            code: "musi",
            description: "Music application suite",
            classes: [playlistClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(model: model, basename: "Music", shouldGenerateClassNamesEnum: false, shouldGenerateStronglyTypedExtensions: false, verbose: false)
        let swiftCode = try generator.generateCode()

        // Verify no strongly typed extensions are generated
        #expect(!swiftCode.contains("Strongly typed accessors"))
        #expect(!swiftCode.contains("public extension MusicPlaylist"))
        #expect(!swiftCode.contains("var tracks: [MusicTrack]"))
    }

    /// Tests all the fixes working together comprehensively.
    ///
    /// This test demonstrates the complete solution covering all reported issues:
    /// - Protocol name capitalization for multi-word classes
    /// - Element array method camelCase conversion
    /// - DocC comment capitalization
    /// - Setter DocC comment generation
    /// - Strongly typed extension generation
    @Test func testAllFixesComprehensive() throws {
        // Create class with multi-word name matching the user's example
        let audioCDTrackClass = SDEFClass(
            name: "audio CD track",
            pluralName: "audio CD tracks",
            code: "cCDT",
            description: "a track on an audio CD",
            inherits: "track",
            properties: [
                SDEFProperty(
                    name: "artist",
                    code: "pArt",
                    type: SDEFPropertyType(baseType: "text", isList: false, isOptional: true),
                    description: "the artist of the CD",
                    access: "",
                    isHidden: false
                )
            ],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        // Create multi-word class matching the user's second example
        let radioTunerPlaylistClass = SDEFClass(
            name: "radio tuner playlist",
            pluralName: "radio tuner playlists",
            code: "cRTP",
            description: "the radio tuner playlist",
            inherits: "playlist",
            properties: [],
            elements: [SDEFElement(type: "audio CD track", cocoaKey: nil)],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Music Suite",
            code: "musi",
            description: "comprehensive test suite",
            classes: [audioCDTrackClass, radioTunerPlaylistClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(
            model: model,
            basename: "Music",
            shouldGenerateClassNamesEnum: false,
            shouldGenerateStronglyTypedExtensions: true,
            verbose: false
        )
        let swiftCode = try generator.generateCode()

        // Test 1: Protocol name capitalization fix
        #expect(swiftCode.contains("@objc public protocol MusicAudioCDTrack:"))
        #expect(swiftCode.contains("@objc public protocol MusicRadioTunerPlaylist:"))
        #expect(!swiftCode.contains("MusicAudiocdtrack"))
        #expect(!swiftCode.contains("MusicRadiotunerplaylist"))

        // Test 2: Element array method camelCase fix
        #expect(swiftCode.contains("@objc optional func audioCDTracks() -> SBElementArray"))
        #expect(!swiftCode.contains("audio cd tracks()"))

        // Test 3: DocC comment capitalization
        #expect(swiftCode.contains("/// A track on an audio CD"))
        #expect(swiftCode.contains("/// The radio tuner playlist"))
        #expect(swiftCode.contains("/// The artist of the CD"))
        #expect(!swiftCode.contains("/// a track on an audio CD"))
        #expect(!swiftCode.contains("/// the radio tuner playlist"))
        #expect(!swiftCode.contains("/// the artist of the CD"))

        // Test 4: Setter DocC comment generation
        #expect(swiftCode.contains("/// Set the artist of the CD"))
        #expect(swiftCode.contains("@objc optional func setArtist(_ artist: String?)"))

        // Test 5: Strongly typed extensions
        #expect(swiftCode.contains("/// Strongly typed accessors for radio tuner playlist"))
        #expect(swiftCode.contains("public extension MusicRadioTunerPlaylist {"))
        #expect(swiftCode.contains("/// Strongly typed accessor for audio CD track elements"))
        #expect(swiftCode.contains("var musicAudioCDTracks: [MusicAudioCDTrack] {"))
        #expect(swiftCode.contains("audioCDTracks?() as? [MusicAudioCDTrack] ?? []"))

        print("✅ All fixes verified: Protocol names, camelCase methods, DocC capitalization, setter comments, and strongly typed extensions")
    }

    /// Tests the complete solution for the user's original examples.
    ///
    /// This test demonstrates the exact examples from the user's request:
    /// - "radio tuner playlist" generates MusicRadioTunerPlaylist (not MusicRadiotunerplaylist)
    /// - "URL tracks" method generates URLTracks() but property generates musicURLTrack
    /// - Strongly typed extensions avoid name clashes by using type prefixes
    @Test func testUserExamples() throws {
        // Test the exact user examples
        let urlTrackClass = SDEFClass(
            name: "URL track",
            pluralName: "URL tracks",
            code: "cURT",
            description: "a track representing a network stream",
            inherits: "track",
            properties: [],
            elements: [],
            respondsTo: [],
            isHidden: false
        )

        let radioTunerPlaylistClass = SDEFClass(
            name: "radio tuner playlist",
            pluralName: "radio tuner playlists",
            code: "cRTP",
            description: "the radio tuner playlist",
            inherits: "playlist",
            properties: [],
            elements: [SDEFElement(type: "URL track", cocoaKey: nil)],
            respondsTo: [],
            isHidden: false
        )

        let suite = SDEFSuite(
            name: "Music Suite",
            code: "musi",
            description: "test suite",
            classes: [urlTrackClass, radioTunerPlaylistClass],
            enumerations: [],
            commands: [],
            classExtensions: []
        )

        let model = SDEFModel(suites: [suite])
        let generator = SDEFSwiftCodeGenerator(
            model: model,
            basename: "Music",
            shouldGenerateClassNamesEnum: false,
            shouldGenerateStronglyTypedExtensions: true,
            verbose: false
        )
        let swiftCode = try generator.generateCode()

        // User's first issue: protocol name capitalization
        #expect(swiftCode.contains("@objc public protocol MusicRadioTunerPlaylist:"))
        #expect(!swiftCode.contains("MusicRadiotunerplaylist"))

        // User's second issue: URLTracks() method exists
        #expect(swiftCode.contains("@objc optional func URLTracks() -> SBElementArray"))

        // User's third issue: strongly typed extension with type prefix to avoid clashes
        #expect(swiftCode.contains("var musicURLTracks: [MusicURLTrack] {"))
        #expect(swiftCode.contains("URLTracks?() as? [MusicURLTrack] ?? []"))

        // Verify no name clash (different names for method vs property)
        #expect(!swiftCode.contains("var URLTracks: [MusicURLTrack]"))

        print("✅ User's original examples verified: MusicRadioTunerPlaylist, URLTracks() method, and musicURLTracks typed property")
    }
}
