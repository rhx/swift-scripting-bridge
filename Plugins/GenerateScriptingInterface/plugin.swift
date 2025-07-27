//
// plugin.swift
// SDEF
//
// Created by Rene Hexel on 1/06/2024.
// Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation
import PackagePlugin

@main
struct GenerateScriptingInterface: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else {
            return []
        }

        // Find all .sdef and .sdefstub files in the target
        let sdefFiles = sourceTarget.sourceFiles(withSuffix: ".sdef")
        let sdefStubFiles = sourceTarget.sourceFiles(withSuffix: ".sdefstub")

        // Combine the file lists
        var allSdefFiles: [File] = []
        allSdefFiles.append(contentsOf: sdefFiles)
        allSdefFiles.append(contentsOf: sdefStubFiles)

        guard !allSdefFiles.isEmpty else {
            return []
        }

        var commands: [Command] = []

        for sdefFile in allSdefFiles {
            let sdefPath = sdefFile.url.path
            let outputDir = context.pluginWorkDirectoryURL

            // Extract base name from the .sdef/.sdefstub file name
            let baseName = sdefFile.url.deletingPathExtension().lastPathComponent
            let outputFile = outputDir.appendingPathComponent("\(baseName).swift")

            // Get the path to the sdef2swift tool
            let sdef2swiftTool = try context.tool(named: "sdef2swift")

            var arguments: [String] = []

            // Handle symlinks and empty files
            let fileManager = FileManager.default
            var resolvedSdefPath = sdefPath

            // Check if it's a symlink
            if let destination = try? fileManager.destinationOfSymbolicLink(atPath: sdefPath) {
                // Return the resolved symlink destination
                if destination.hasPrefix("/") {
                    resolvedSdefPath = destination
                } else {
                    // Relative symlink - resolve relative to the symlink's directory
                    let parentDir = URL(fileURLWithPath: sdefPath).deletingLastPathComponent()
                    resolvedSdefPath = parentDir.appendingPathComponent(destination).path
                }
            } else {
                // Check if the file is empty or is a .sdefstub file
                let url = URL(fileURLWithPath: sdefPath)
                let isStubFile = url.pathExtension == "sdefstub"
                let isEmpty = (try? Data(contentsOf: url))?.isEmpty ?? false

                if isStubFile || isEmpty {
                    // Return just the basename - let sdef2swift handle the search
                    resolvedSdefPath = baseName
                }
            }

            arguments.append(resolvedSdefPath)

            // Add output directory
            arguments.append("--output-directory")
            arguments.append(outputDir.path)

            // Add base name
            arguments.append("--basename")
            arguments.append(baseName)

            let command = Command.buildCommand(
                displayName: "Generate Swift interface for \(baseName)",
                executable: sdef2swiftTool.url,
                arguments: arguments,
                inputFiles: [sdefFile.url],
                outputFiles: [outputFile]
            )

            commands.append(command)
        }

        return commands
    }
}
