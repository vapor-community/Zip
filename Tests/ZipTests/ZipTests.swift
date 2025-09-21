//
//  ZipTests.swift
//  ZipTests
//
//  Created by Roy Marmelstein on 13/12/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation
import Testing

@testable import Zip

@Suite("Zip Tests", .serialized)
struct ZipTests {
    private func url(forResource resource: String, withExtension ext: String? = nil) -> URL? {
        Bundle.module.url(forResource: "TestResources/\(resource)", withExtension: ext)
    }

    private func withSandbox(_ block: (URL) throws -> Void) throws {
        let sandbox = FileManager.default.temporaryDirectory.appendingPathComponent("ZipTests_" + UUID().uuidString, isDirectory: true)
        // We can always create it. UUID should be unique.
        try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true, attributes: nil)

        try block(sandbox)

        do {
            try FileManager.default.removeItem(at: sandbox)
        } catch {
            print("Could not remove test sandbox at '\(sandbox.path)': \(error)")
        }
    }

    @Test("Quick Unzip")
    func quickUnzip() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationURL = try Zip.quickUnzipFile(filePath)
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(try Data(contentsOf: destinationURL.appendingPathComponent("3crBXeO.gif")).count > 0)
        #expect(try Data(contentsOf: destinationURL.appendingPathComponent("kYkLkPf.gif")).count > 0)
    }

    @Test("Quick Unzip with Non-Existing Path")
    func quickUnzipNonExistingPath() {
        let filePath = URL(fileURLWithPath: "/some/path/to/nowhere/bb9.zip")
        #expect(throws: (any Error).self) { try Zip.quickUnzipFile(filePath) }
    }

    @Test("Quick Unzip with Non-Zip Path")
    func quickUnzipNonZipPath() {
        let filePath = url(forResource: "3crBXeO", withExtension: "gif")!
        #expect(throws: (any Error).self) { try Zip.quickUnzipFile(filePath) }
    }

    @Test("Quick Unzip with Progress")
    func quickUnzipProgress() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationURL = try Zip.quickUnzipFile(filePath) { progress in
            #expect(!progress.isNaN)
        }
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(try Data(contentsOf: destinationURL.appendingPathComponent("3crBXeO.gif")).count > 0)
        #expect(try Data(contentsOf: destinationURL.appendingPathComponent("kYkLkPf.gif")).count > 0)
    }

    @Test("Quick Unzip with Online URL")
    func quickUnzipOnlineURL() {
        let filePath = URL(string: "http://www.google.com/google.zip")!
        #expect(throws: (any Error).self) { try Zip.quickUnzipFile(filePath) }
    }

    @Test("Unzip")
    func unzip() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!

        try withSandbox { destinationPath in
            #expect(throws: Never.self) {
                try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
            }

            #expect(FileManager.default.fileExists(atPath: destinationPath.path))
            try #expect(Data(contentsOf: destinationPath.appendingPathComponent("3crBXeO.gif")).count > 0)
            try #expect(Data(contentsOf: destinationPath.appendingPathComponent("kYkLkPf.gif")).count > 0)
        }
    }

    @Test("Implicit Progress Unzip")
    func implicitProgressUnzip() throws {
        let progress = Progress(totalUnitCount: 1)

        let filePath = url(forResource: "bb8", withExtension: "zip")!

        try withSandbox { destinationPath in
            progress.becomeCurrent(withPendingUnitCount: 1)
            try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
            progress.resignCurrent()

            #expect(progress.totalUnitCount == progress.completedUnitCount)
        }
    }

    @Test("Implicit Progress Zip")
    func implicitProgressZip() throws {
        let progress = Progress(totalUnitCount: 1)

        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        try withSandbox { sandboxFolder in
            let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")

            progress.becomeCurrent(withPendingUnitCount: 1)
            try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: nil, progress: nil)
            progress.resignCurrent()

            #expect(progress.totalUnitCount == progress.completedUnitCount)
        }
    }

    @Test("Quick Zip")
    func quickZip() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let destinationURL = try Zip.quickZipFiles([imageURL1, imageURL2], fileName: "archive.zip")
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(try Data(contentsOf: destinationURL).count > 0)
    }

    @Test("Quick Zip with Progress")
    func quickZipProgress() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let destinationURL = try Zip.quickZipFiles([imageURL1, imageURL2], fileName: "archive") { progress in
            #expect(!progress.isNaN)
        }
        defer {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(try Data(contentsOf: destinationURL).count > 0)
    }

    @Test("Quick Zip Folder")
    func quickZipFolder() throws {
        let fileManager = FileManager.default
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        try withSandbox { folderURL in
            let targetImageURL1 = folderURL.appendingPathComponent("3crBXeO.gif")
            let targetImageURL2 = folderURL.appendingPathComponent("kYkLkPf.gif")
            try fileManager.copyItem(at: imageURL1, to: targetImageURL1)
            try fileManager.copyItem(at: imageURL2, to: targetImageURL2)
            let destinationURL = try Zip.quickZipFiles([folderURL], fileName: "directory")
            defer {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            #expect(fileManager.fileExists(atPath: destinationURL.path))
        }
    }

    @Test("Zip")
    func zip() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        try withSandbox { sandboxFolder in
            let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
            #expect(throws: Never.self) {
                try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: nil, progress: nil)
            }
            #expect(FileManager.default.fileExists(atPath: zipFilePath.path))
        }
    }

    @Test("Zip and Unzip with Password")
    func zipUnzipPassword() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        try withSandbox { firstSandbox in
            let zipFilePath = firstSandbox.appendingPathComponent("archive.zip")
            try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: "password", progress: nil)
            let fileManager = FileManager.default
            #expect(fileManager.fileExists(atPath: zipFilePath.path))
            let directoryName = zipFilePath.lastPathComponent.replacingOccurrences(of: ".\(zipFilePath.pathExtension)", with: "")
            try withSandbox { secondSandbox in
                let destinationUrl = secondSandbox.appendingPathComponent(directoryName, isDirectory: true)
                try Zip.unzipFile(zipFilePath, destination: destinationUrl, overwrite: true, password: "password", progress: nil)
                #expect(fileManager.fileExists(atPath: destinationUrl.path))
            }
        }
    }

    @Test("Unzip with Unsupported Permissions")
    func unzipWithUnsupportedPermissions() throws {
        let permissionsURL = url(forResource: "unsupported_permissions", withExtension: "zip")!
        let unzipDestination = try Zip.quickUnzipFile(permissionsURL)
        let permission644 = unzipDestination.appendingPathComponent("unsupported_permission").appendingPathExtension("txt")
        let foundPermissions = try FileManager.default.attributesOfItem(atPath: permission644.path)[.posixPermissions] as? Int
        #if os(Windows)
        let expectedPermissions = 0o600
        #elseif os(Android)
        let expectedPermissions = 0o666
        #else
        let expectedPermissions = 0o644
        #endif
        try #require(foundPermissions != nil)
        #expect(
            foundPermissions == expectedPermissions,
            "\(foundPermissions.map { String($0, radix: 8) } ?? "nil") is not equal to \(String(expectedPermissions, radix: 8))"
        )
    }

    @Test("Unzip with Permissions")
    func unzipPermissions() throws {
        let permissionsURL = url(forResource: "permissions", withExtension: "zip")!
        let unzipDestination = try Zip.quickUnzipFile(permissionsURL)
        defer {
            try? FileManager.default.removeItem(at: unzipDestination)
        }
        let fileManager = FileManager.default
        let permission777 = unzipDestination.appendingPathComponent("permission_777").appendingPathExtension("txt")
        let permission600 = unzipDestination.appendingPathComponent("permission_600").appendingPathExtension("txt")
        let permission604 = unzipDestination.appendingPathComponent("permission_604").appendingPathExtension("txt")

        let attributes777 = try fileManager.attributesOfItem(atPath: permission777.path)
        let attributes600 = try fileManager.attributesOfItem(atPath: permission600.path)
        let attributes604 = try fileManager.attributesOfItem(atPath: permission604.path)
        #if os(Windows)
        #expect(attributes777[.posixPermissions] as? Int == 0o600)
        #expect(attributes600[.posixPermissions] as? Int == 0o600)
        #expect(attributes604[.posixPermissions] as? Int == 0o600)
        #else
        #expect(attributes777[.posixPermissions] as? Int == 0o777)
        #expect(attributes600[.posixPermissions] as? Int == 0o600)
        #expect(attributes604[.posixPermissions] as? Int == 0o604)
        #endif
    }

    @Test("Unzip protects against Path Traversal", .bug("https://github.com/marmelroy/Zip/issues/245"))
    func unzipProtectsAgainstPathTraversal() throws {
        let filePath = url(forResource: "pathTraversal", withExtension: "zip")!
        try withSandbox { destinationPath in
            do {
                try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
                Issue.record("ZipError.unzipFail expected.")
            } catch {}

            #expect(
                !FileManager.default.fileExists(
                    atPath: destinationPath.appendingPathComponent("../naughtyFile.txt").path
                )
            )
        }
    }

    @Test("Quick Unzip Subdirectory")
    func quickUnzipSubDir() throws {
        let bookURL = url(forResource: "bb8", withExtension: "zip")!
        let unzipDestination = try Zip.quickUnzipFile(bookURL)
        defer {
            try? FileManager.default.removeItem(at: unzipDestination)
        }
        let fileManager = FileManager.default
        let subDir = unzipDestination.appendingPathComponent("subDir")
        let imageURL = subDir.appendingPathComponent("r2W9yu9").appendingPathExtension("gif")

        #expect(fileManager.fileExists(atPath: unzipDestination.path))
        #expect(fileManager.fileExists(atPath: subDir.path))
        #expect(fileManager.fileExists(atPath: imageURL.path))
    }

    @Test("Added Custom File Extension Is Valid")
    func addedCustomFileExtensionIsValid() {
        let fileExtension = "cstm"
        Zip.addCustomFileExtension(fileExtension)
        let result = Zip.isValidFileExtension(fileExtension)
        #expect(result)
        Zip.removeCustomFileExtension(fileExtension)
    }

    @Test("Removed Custom File Extension Is Invalid")
    func removedCustomFileExtensionIsInvalid() {
        let fileExtension = "cstm"
        Zip.addCustomFileExtension(fileExtension)
        Zip.removeCustomFileExtension(fileExtension)
        let result = Zip.isValidFileExtension(fileExtension)
        #expect(!result)
    }

    @Test("Default File Extensions Are Valid", arguments: ["zip", "cbz"])
    func defaultFileExtensionsIsValid(fileExtension: String) {
        #expect(Zip.isValidFileExtension(fileExtension))
    }

    @Test("Default File Extensions Are Not Removed", arguments: ["zip", "cbz"])
    func defaultFileExtensionsAreNotRemoved(fileExtension: String) {
        Zip.removeCustomFileExtension(fileExtension)
        #expect(Zip.isValidFileExtension(fileExtension))
    }

    @Test("Zip Data")
    func zipData() throws {
        let archiveFile1 = ArchiveFile(filename: "file1.txt", data: "Hello, World!".data(using: .utf8)!)
        let archiveFile2 = ArchiveFile(
            filename: "file2.txt",
            data: NSData(data: "Hi Mom!".data(using: .utf8)!),
            modifiedTime: Date()
        )
        let emptyArchiveFile = ArchiveFile(filename: "empty.txt", data: Data())
        try withSandbox { sandboxFolder in
            let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
            try Zip.zipData(archiveFiles: [archiveFile1, archiveFile2, emptyArchiveFile], zipFilePath: zipFilePath)
            #expect(FileManager.default.fileExists(atPath: zipFilePath.path))
        }
    }

    @Test("Zip Data with Progress")
    func zipDataProgress() throws {
        let archiveFile1 = ArchiveFile(filename: "file1.txt", data: "Hello, World!".data(using: .utf8)!)
        let archiveFile2 = ArchiveFile(
            filename: "file2.txt",
            data: NSData(data: "Hi Mom!".data(using: .utf8)!),
            modifiedTime: Date()
        )
        let emptyArchiveFile = ArchiveFile(filename: "empty.txt", data: Data())
        try withSandbox { sandboxFolder in
            let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
            try Zip.zipData(archiveFiles: [archiveFile1, archiveFile2, emptyArchiveFile], zipFilePath: zipFilePath) { progress in
                #expect(!progress.isNaN)
            }
            #expect(FileManager.default.fileExists(atPath: zipFilePath.path))
        }
    }

    @Test("Zip Error")
    func zipError() {
        #expect(ZipError.fileNotFound.description == "File not found.")
        #expect(ZipError.unzipFail.description == "Failed to unzip file.")
        #expect(ZipError.zipFail.description == "Failed to zip file.")
    }

    @Test("Zip Compression")
    func zipCompression() {
        #expect(ZipCompression.NoCompression.minizipCompression == 0)
        #expect(ZipCompression.BestSpeed.minizipCompression == 1)
        #expect(ZipCompression.DefaultCompression.minizipCompression == -1)
        #expect(ZipCompression.BestCompression.minizipCompression == 9)
    }

    @Test("DOS Date")
    func dosDate() {
        NSTimeZone.default = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
        #expect(0b10000011_00110001_10001100_00110001 == Date(timeIntervalSince1970: 2_389_282_415).dosDate)
        #expect(0b00000001_00110001_10001100_00110001 == Date(timeIntervalSince1970: 338_060_015).dosDate)
        #expect(0b00000000_00100001_00000000_00000000 == Date(timeIntervalSince1970: 315_532_800).dosDate)
    }

    @Test("Zip Init")
    func zipInit() {
        var zip: Zip? = Zip()
        #expect(zip != nil)
        zip = nil
        #expect(zip == nil)
    }

    @Test("Unzip Without Password")
    func unzipWithoutPassword() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        try withSandbox { firstSandbox in
            let zipFilePath = firstSandbox.appendingPathComponent("archive.zip")
            try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: "password")
            #expect(FileManager.default.fileExists(atPath: zipFilePath.path))
            let directoryName = zipFilePath.lastPathComponent.replacingOccurrences(of: ".\(zipFilePath.pathExtension)", with: "")
            try withSandbox { secondSandbox in
                let destinationUrl = secondSandbox.appendingPathComponent(directoryName, isDirectory: true)
                #expect(throws: (any Error).self) { try Zip.unzipFile(zipFilePath, destination: destinationUrl) }
            }
        }
    }

    @Test("File Handler")
    func fileHandler() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        try withSandbox { destinationPath in
            #expect(throws: Never.self) {
                try Zip.unzipFile(
                    filePath, destination: destinationPath, password: "password",
                    fileOutputHandler: { fileURL in
                        #expect(FileManager.default.fileExists(atPath: fileURL.path))
                    }
                )
            }
            #expect(FileManager.default.fileExists(atPath: destinationPath.path))
            try #expect(Data(contentsOf: destinationPath.appendingPathComponent("3crBXeO.gif")).count > 0)
            try #expect(Data(contentsOf: destinationPath.appendingPathComponent("kYkLkPf.gif")).count > 0)
        }
    }

    @Test("Round Tripping", .bug("https://github.com/vapor-community/Zip/issues/4"))
    func roundTripping() throws {
        // "prod-apple-swift-metrics-main-e6a00d36.zip" is the original zip file from the issue.
        let zipFilePath = url(forResource: "prod-apple-swift-metrics-main-e6a00d36", withExtension: "zip")!
        try withSandbox { failDestinationPath in
            #expect(throws: (any Error).self) { try Zip.unzipFile(zipFilePath, destination: failDestinationPath, overwrite: true) }
        }

        // "prod-apple-swift-metrics-main-e6a00d36-finder.zip" is a zip file
        // that was created by unzipping the original zip file with Finder on macOS 14.6.1
        // and then zipping it again using Finder on macOS 14.6.1.

        // "prod-apple-swift-metrics-main-e6a00d36-test.zip" is a zip file
        // that was created by unzipping the original zip file with Finder on macOS 14.6.1
        // and then zipping it again using vapor-community/Zip v2.2.0.
        let testZipFilePath = url(forResource: "prod-apple-swift-metrics-main-e6a00d36-test", withExtension: "zip")!
        try withSandbox { destinationPath in
            #expect(throws: Never.self) { try Zip.unzipFile(testZipFilePath, destination: destinationPath, overwrite: true) }

            let destinationFolder = destinationPath.appendingPathComponent("prod-apple-swift-metrics-main-e6a00d36")
            #expect(FileManager.default.fileExists(atPath: destinationFolder.appendingPathComponent("metadata.json").path))
            #expect(FileManager.default.fileExists(atPath: destinationFolder.appendingPathComponent("main/index.html").path))
            #expect(FileManager.default.fileExists(atPath: destinationFolder.appendingPathComponent("main/index/index.json").path))
            #expect(try Data(contentsOf: destinationFolder.appendingPathComponent("metadata.json")).count > 0)

            let unzippedFiles = try FileManager.default.contentsOfDirectory(atPath: destinationFolder.path)

            try withSandbox { sandbox in
                let newZipFilePath = sandbox.appendingPathComponent("new-archive.zip")
                try Zip.zipFiles(paths: [destinationFolder], zipFilePath: newZipFilePath)

                try withSandbox { newDestinationPath in
                    try Zip.unzipFile(newZipFilePath, destination: newDestinationPath, overwrite: true)

                    let newDestinationFolder = newDestinationPath.appendingPathComponent("prod-apple-swift-metrics-main-e6a00d36")
                    #expect(FileManager.default.fileExists(atPath: newDestinationFolder.appendingPathComponent("metadata.json").path))
                    #expect(FileManager.default.fileExists(atPath: newDestinationFolder.appendingPathComponent("main/index.html").path))
                    #expect(
                        FileManager.default.fileExists(atPath: newDestinationFolder.appendingPathComponent("main/index/index.json").path)
                    )
                    #expect(try Data(contentsOf: newDestinationFolder.appendingPathComponent("metadata.json")).count > 0)

                    let newUnzippedFiles = try FileManager.default.contentsOfDirectory(atPath: newDestinationFolder.path)
                    #expect(unzippedFiles == newUnzippedFiles)
                }
            }
        }
    }

    #if os(Windows)
    @Test("Windows Reserved Characters")
    func windowsReservedChars() throws {
        let txtFile = ArchiveFile(filename: "a_b.txt", data: "Hi Mom!".data(using: .utf8)!)
        let txtFile1 = ArchiveFile(filename: "a<b.txt", data: "Hello, Zip!".data(using: .utf8)!)
        let txtFile2 = ArchiveFile(filename: "a>b.txt", data: "Hello, Swift!".data(using: .utf8)!)
        let txtFile3 = ArchiveFile(filename: "a:b.txt", data: "Hello, World!".data(using: .utf8)!)
        let txtFile4 = ArchiveFile(filename: "a\"b.txt", data: "Hi Windows!".data(using: .utf8)!)
        let txtFile5 = ArchiveFile(filename: "a|b.txt", data: "Hi Barbie!".data(using: .utf8)!)
        let txtFile6 = ArchiveFile(filename: "a?b.txt", data: "Hi, Ken!".data(using: .utf8)!)
        let txtFile7 = ArchiveFile(filename: "a*b.txt", data: "Hello Everyone!".data(using: .utf8)!)

        let file = ArchiveFile(filename: "a_b", data: "Hello, World!".data(using: .utf8)!)
        let file1 = ArchiveFile(filename: "a<b", data: "Hello, Zip!".data(using: .utf8)!)
        let file2 = ArchiveFile(filename: "a>b", data: "Hello, Swift!".data(using: .utf8)!)
        let file3 = ArchiveFile(filename: "a:b", data: "Hello, World!".data(using: .utf8)!)

        try withSandbox { sandboxFolder in
            let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
            try Zip.zipData(
                archiveFiles: [
                    txtFile, txtFile1, txtFile2, txtFile3, txtFile4, txtFile5, txtFile6, txtFile7,
                    file, file1, file2, file3,
                ],
                zipFilePath: zipFilePath
            )

            try withSandbox { destinationPath in
                try Zip.unzipFile(zipFilePath, destination: destinationPath)

                let txtFileURL = destinationPath.appendingPathComponent("a_b.txt")
                let txtFile1URL = destinationPath.appendingPathComponent("a_b (1).txt")
                let txtFile2URL = destinationPath.appendingPathComponent("a_b (2).txt")
                let txtFile3URL = destinationPath.appendingPathComponent("a_b (3).txt")
                let txtFile4URL = destinationPath.appendingPathComponent("a_b (4).txt")
                let txtFile5URL = destinationPath.appendingPathComponent("a_b (5).txt")
                let txtFile6URL = destinationPath.appendingPathComponent("a_b (6).txt")
                let txtFile7URL = destinationPath.appendingPathComponent("a_b (7).txt")

                let fileURL = destinationPath.appendingPathComponent("a_b")
                let file1URL = destinationPath.appendingPathComponent("a_b (1)")
                let file2URL = destinationPath.appendingPathComponent("a_b (2)")
                let file3URL = destinationPath.appendingPathComponent("a_b (3)")

                #expect(FileManager.default.fileExists(atPath: txtFileURL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile1URL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile2URL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile3URL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile4URL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile5URL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile6URL.path))
                #expect(FileManager.default.fileExists(atPath: txtFile7URL.path))

                #expect(FileManager.default.fileExists(atPath: fileURL.path))
                #expect(FileManager.default.fileExists(atPath: file1URL.path))
                #expect(FileManager.default.fileExists(atPath: file2URL.path))
                #expect(FileManager.default.fileExists(atPath: file3URL.path))
            }
        }
    }
    #endif

    @Test("PassKit Extensions")
    func passKitExtensions() throws {
        let pkpassURL = url(forResource: "PassKitTest", withExtension: "pkpass")!
        try withSandbox { pkpassDestination in
            Zip.addCustomFileExtension("pkpass")
            #expect(throws: Never.self) { try Zip.unzipFile(pkpassURL, destination: pkpassDestination) }
            #expect(FileManager.default.fileExists(atPath: pkpassDestination.appendingPathComponent("pass.json").path))
            #expect(FileManager.default.fileExists(atPath: pkpassDestination.appendingPathComponent("manifest.json").path))
            #expect(FileManager.default.fileExists(atPath: pkpassDestination.appendingPathComponent("signature").path))
            #expect(FileManager.default.fileExists(atPath: pkpassDestination.appendingPathComponent("icon.png").path))
            #expect(FileManager.default.fileExists(atPath: pkpassDestination.appendingPathComponent("logo.png").path))
        }

        let orderURL = url(forResource: "PassKitTest", withExtension: "order")!
        try withSandbox { orderDestination in
            Zip.addCustomFileExtension("order")
            #expect(throws: Never.self) { try Zip.unzipFile(orderURL, destination: orderDestination) }
            #expect(FileManager.default.fileExists(atPath: orderDestination.appendingPathComponent("order.json").path))
            #expect(FileManager.default.fileExists(atPath: orderDestination.appendingPathComponent("manifest.json").path))
            #expect(FileManager.default.fileExists(atPath: orderDestination.appendingPathComponent("signature").path))
            #expect(FileManager.default.fileExists(atPath: orderDestination.appendingPathComponent("icon.png").path))
        }
    }
}
