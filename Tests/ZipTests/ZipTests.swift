//
//  ZipTests.swift
//  ZipTests
//
//  Created by Roy Marmelstein on 13/12/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import XCTest

@testable import Zip

final class ZipTests: XCTestCase {
    private func url(forResource resource: String, withExtension ext: String? = nil) -> URL? {
        let resourcePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent(resource)
        return ext.map { resourcePath.appendingPathExtension($0) } ?? resourcePath
    }

    private func autoRemovingSandbox() throws -> URL {
        let sandbox = FileManager.default.temporaryDirectory.appendingPathComponent("ZipTests_" + UUID().uuidString, isDirectory: true)
        // We can always create it. UUID should be unique.
        try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true, attributes: nil)
        // Schedule the teardown block _after_ the directory has been created (so that if it fails, no teardown block is registered).
        addTeardownBlock {
            do {
                try FileManager.default.removeItem(at: sandbox)
            } catch {
                print("Could not remove test sandbox at '\(sandbox.path)': \(error)")
            }
        }
        return sandbox
    }

    func testQuickUnzip() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationURL = try Zip.quickUnzipFile(filePath)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationURL.appendingPathComponent("3crBXeO.gif")).count, 0)
        try XCTAssertGreaterThan(Data(contentsOf: destinationURL.appendingPathComponent("kYkLkPf.gif")).count, 0)
    }

    func testQuickUnzipNonExistingPath() {
        let filePath = URL(fileURLWithPath: "/some/path/to/nowhere/bb9.zip")
        XCTAssertThrowsError(try Zip.quickUnzipFile(filePath))
    }

    func testQuickUnzipNonZipPath() {
        let filePath = url(forResource: "3crBXeO", withExtension: "gif")!
        XCTAssertThrowsError(try Zip.quickUnzipFile(filePath))
    }

    func testQuickUnzipProgress() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationURL = try Zip.quickUnzipFile(filePath) { progress in
            XCTAssertFalse(progress.isNaN)
        }
        addTeardownBlock {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationURL.appendingPathComponent("3crBXeO.gif")).count, 0)
        try XCTAssertGreaterThan(Data(contentsOf: destinationURL.appendingPathComponent("kYkLkPf.gif")).count, 0)
    }

    func testQuickUnzipOnlineURL() {
        let filePath = URL(string: "http://www.google.com/google.zip")!
        XCTAssertThrowsError(try Zip.quickUnzipFile(filePath))
    }

    func testUnzip() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()

        XCTAssertNoThrow(try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil))

        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationPath.path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationPath.appendingPathComponent("3crBXeO.gif")).count, 0)
        try XCTAssertGreaterThan(Data(contentsOf: destinationPath.appendingPathComponent("kYkLkPf.gif")).count, 0)
    }

    func testImplicitProgressUnzip() throws {
        let progress = Progress(totalUnitCount: 1)

        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()

        progress.becomeCurrent(withPendingUnitCount: 1)
        try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
        progress.resignCurrent()

        XCTAssertTrue(progress.totalUnitCount == progress.completedUnitCount)
    }

    func testImplicitProgressZip() throws {
        let progress = Progress(totalUnitCount: 1)

        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let sandboxFolder = try autoRemovingSandbox()
        let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")

        progress.becomeCurrent(withPendingUnitCount: 1)
        try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: nil, progress: nil)
        progress.resignCurrent()

        XCTAssertTrue(progress.totalUnitCount == progress.completedUnitCount)
    }

    func testQuickZip() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let destinationURL = try Zip.quickZipFiles([imageURL1, imageURL2], fileName: "archive.zip")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationURL).count, 0)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: destinationURL)
        }
    }

    func testQuickZipProgress() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let destinationURL = try Zip.quickZipFiles([imageURL1, imageURL2], fileName: "archive") { progress in
            XCTAssertFalse(progress.isNaN)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationURL).count, 0)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: destinationURL)
        }
    }

    func testQuickZipFolder() throws {
        let fileManager = FileManager.default
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let folderURL = try autoRemovingSandbox()
        let targetImageURL1 = folderURL.appendingPathComponent("3crBXeO.gif")
        let targetImageURL2 = folderURL.appendingPathComponent("kYkLkPf.gif")
        try fileManager.copyItem(at: imageURL1, to: targetImageURL1)
        try fileManager.copyItem(at: imageURL2, to: targetImageURL2)
        let destinationURL = try Zip.quickZipFiles([folderURL], fileName: "directory")
        XCTAssertTrue(fileManager.fileExists(atPath: destinationURL.path))
        addTeardownBlock {
            try? FileManager.default.removeItem(at: destinationURL)
        }
    }

    func testZip() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let sandboxFolder = try autoRemovingSandbox()
        let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
        XCTAssertNoThrow(try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: nil, progress: nil))
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipFilePath.path))
    }

    func testZipUnzipPassword() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let zipFilePath = try autoRemovingSandbox().appendingPathComponent("archive.zip")
        try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: "password", progress: nil)
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: zipFilePath.path))
        let directoryName = zipFilePath.lastPathComponent.replacingOccurrences(of: ".\(zipFilePath.pathExtension)", with: "")
        let destinationUrl = try autoRemovingSandbox().appendingPathComponent(directoryName, isDirectory: true)
        try Zip.unzipFile(zipFilePath, destination: destinationUrl, overwrite: true, password: "password", progress: nil)
        XCTAssertTrue(fileManager.fileExists(atPath: destinationUrl.path))
    }

    func testUnzipWithUnsupportedPermissions() throws {
        let permissionsURL = url(forResource: "unsupported_permissions", withExtension: "zip")!
        let unzipDestination = try Zip.quickUnzipFile(permissionsURL)
        let permission644 = unzipDestination.appendingPathComponent("unsupported_permission").appendingPathExtension("txt")
        let foundPermissions = try FileManager.default.attributesOfItem(atPath: permission644.path)[.posixPermissions] as? Int
        #if os(Windows) && compiler(<6.0)
            let expectedPermissions = 0o700
        #elseif os(Windows) && compiler(>=6.0)
            let expectedPermissions = 0o600
        #else
            let expectedPermissions = 0o644
        #endif
        XCTAssertNotNil(foundPermissions)
        XCTAssertEqual(
            foundPermissions,
            expectedPermissions,
            "\(foundPermissions.map { String($0, radix: 8) } ?? "nil") is not equal to \(String(expectedPermissions, radix: 8))"
        )
    }

    func testUnzipPermissions() throws {
        let permissionsURL = url(forResource: "permissions", withExtension: "zip")!
        let unzipDestination = try Zip.quickUnzipFile(permissionsURL)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: unzipDestination)
        }
        let fileManager = FileManager.default
        let permission777 = unzipDestination.appendingPathComponent("permission_777").appendingPathExtension("txt")
        let permission600 = unzipDestination.appendingPathComponent("permission_600").appendingPathExtension("txt")
        let permission604 = unzipDestination.appendingPathComponent("permission_604").appendingPathExtension("txt")

        let attributes777 = try fileManager.attributesOfItem(atPath: permission777.path)
        let attributes600 = try fileManager.attributesOfItem(atPath: permission600.path)
        let attributes604 = try fileManager.attributesOfItem(atPath: permission604.path)
        #if os(Windows) && compiler(<6.0)
            XCTAssertEqual(attributes777[.posixPermissions] as? Int, 0o700)
            XCTAssertEqual(attributes600[.posixPermissions] as? Int, 0o700)
            XCTAssertEqual(attributes604[.posixPermissions] as? Int, 0o700)
        #elseif os(Windows) && compiler(>=6.0)
            XCTAssertEqual(attributes777[.posixPermissions] as? Int, 0o600)
            XCTAssertEqual(attributes600[.posixPermissions] as? Int, 0o600)
            XCTAssertEqual(attributes604[.posixPermissions] as? Int, 0o600)
        #else
            XCTAssertEqual(attributes777[.posixPermissions] as? Int, 0o777)
            XCTAssertEqual(attributes600[.posixPermissions] as? Int, 0o600)
            XCTAssertEqual(attributes604[.posixPermissions] as? Int, 0o604)
        #endif
    }

    // Tests if https://github.com/marmelroy/Zip/issues/245 does not uccor anymore.
    func testUnzipProtectsAgainstPathTraversal() throws {
        let filePath = url(forResource: "pathTraversal", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()

        do {
            try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
            XCTFail("ZipError.unzipFail expected.")
        } catch {}

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: destinationPath.appendingPathComponent("../naughtyFile.txt").path
            )
        )
    }

    func testQuickUnzipSubDir() throws {
        let bookURL = url(forResource: "bb8", withExtension: "zip")!
        let unzipDestination = try Zip.quickUnzipFile(bookURL)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: unzipDestination)
        }
        let fileManager = FileManager.default
        let subDir = unzipDestination.appendingPathComponent("subDir")
        let imageURL = subDir.appendingPathComponent("r2W9yu9").appendingPathExtension("gif")

        XCTAssertTrue(fileManager.fileExists(atPath: unzipDestination.path))
        XCTAssertTrue(fileManager.fileExists(atPath: subDir.path))
        XCTAssertTrue(fileManager.fileExists(atPath: imageURL.path))
    }

    func testAddedCustomFileExtensionIsValid() {
        let fileExtension = "cstm"
        Zip.addCustomFileExtension(fileExtension)
        let result = Zip.isValidFileExtension(fileExtension)
        XCTAssertTrue(result)
        Zip.removeCustomFileExtension(fileExtension)
    }

    func testRemovedCustomFileExtensionIsInvalid() {
        let fileExtension = "cstm"
        Zip.addCustomFileExtension(fileExtension)
        Zip.removeCustomFileExtension(fileExtension)
        let result = Zip.isValidFileExtension(fileExtension)
        XCTAssertFalse(result)
    }

    func testDefaultFileExtensionsIsValid() {
        XCTAssertTrue(Zip.isValidFileExtension("zip"))
        XCTAssertTrue(Zip.isValidFileExtension("cbz"))
    }

    func testDefaultFileExtensionsIsNotRemoved() {
        Zip.removeCustomFileExtension("zip")
        Zip.removeCustomFileExtension("cbz")
        XCTAssertTrue(Zip.isValidFileExtension("zip"))
        XCTAssertTrue(Zip.isValidFileExtension("cbz"))
    }

    func testZipData() throws {
        let archiveFile1 = ArchiveFile(filename: "file1.txt", data: "Hello, World!".data(using: .utf8)!)
        let archiveFile2 = ArchiveFile(
            filename: "file2.txt",
            data: NSData(data: "Hi Mom!".data(using: .utf8)!),
            modifiedTime: Date()
        )
        let emptyArchiveFile = ArchiveFile(filename: "empty.txt", data: Data())
        let sandboxFolder = try autoRemovingSandbox()
        let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
        try Zip.zipData(archiveFiles: [archiveFile1, archiveFile2, emptyArchiveFile], zipFilePath: zipFilePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipFilePath.path))
    }

    func testZipDataProgress() throws {
        let archiveFile1 = ArchiveFile(filename: "file1.txt", data: "Hello, World!".data(using: .utf8)!)
        let archiveFile2 = ArchiveFile(
            filename: "file2.txt",
            data: NSData(data: "Hi Mom!".data(using: .utf8)!),
            modifiedTime: Date()
        )
        let emptyArchiveFile = ArchiveFile(filename: "empty.txt", data: Data())
        let sandboxFolder = try autoRemovingSandbox()
        let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
        try Zip.zipData(archiveFiles: [archiveFile1, archiveFile2, emptyArchiveFile], zipFilePath: zipFilePath) { progress in
            XCTAssertFalse(progress.isNaN)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipFilePath.path))
    }

    func testZipError() {
        XCTAssertEqual(ZipError.fileNotFound.description, "File not found.")
        XCTAssertEqual(ZipError.unzipFail.description, "Failed to unzip file.")
        XCTAssertEqual(ZipError.zipFail.description, "Failed to zip file.")
    }

    func testZipCompression() {
        XCTAssertEqual(ZipCompression.NoCompression.minizipCompression, 0)
        XCTAssertEqual(ZipCompression.BestSpeed.minizipCompression, 1)
        XCTAssertEqual(ZipCompression.DefaultCompression.minizipCompression, -1)
        XCTAssertEqual(ZipCompression.BestCompression.minizipCompression, 9)
    }

    func testDosDate() {
        XCTAssertEqual(0b10000011_00110001_10001100_00110001, Date(timeIntervalSince1970: 2_389_282_415).dosDate)
        XCTAssertEqual(0b00000001_00110001_10001100_00110001, Date(timeIntervalSince1970: 338_060_015).dosDate)
        XCTAssertEqual(0b00000000_00100001_00000000_00000000, Date(timeIntervalSince1970: 315_532_800).dosDate)
    }

    func testInit() {
        var zip: Zip? = Zip()
        XCTAssertNotNil(zip)
        zip = nil
        XCTAssertNil(zip)
    }

    func testUnzipWithoutPassword() throws {
        let imageURL1 = url(forResource: "3crBXeO", withExtension: "gif")!
        let imageURL2 = url(forResource: "kYkLkPf", withExtension: "gif")!
        let zipFilePath = try autoRemovingSandbox().appendingPathComponent("archive.zip")
        try Zip.zipFiles(paths: [imageURL1, imageURL2], zipFilePath: zipFilePath, password: "password")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipFilePath.path))
        let directoryName = zipFilePath.lastPathComponent.replacingOccurrences(of: ".\(zipFilePath.pathExtension)", with: "")
        let destinationUrl = try autoRemovingSandbox().appendingPathComponent(directoryName, isDirectory: true)
        XCTAssertThrowsError(try Zip.unzipFile(zipFilePath, destination: destinationUrl))
    }

    func testFileHandler() throws {
        let filePath = url(forResource: "bb8", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()
        XCTAssertNoThrow(
            try Zip.unzipFile(
                filePath, destination: destinationPath, password: "password",
                fileOutputHandler: { fileURL in
                    XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
                }
            )
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationPath.path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationPath.appendingPathComponent("3crBXeO.gif")).count, 0)
        try XCTAssertGreaterThan(Data(contentsOf: destinationPath.appendingPathComponent("kYkLkPf.gif")).count, 0)
    }

    // Tests if https://github.com/vapor-community/Zip/issues/4 does not occur anymore.
    func testRoundTripping() throws {
        // "prod-apple-swift-metrics-main-e6a00d36.zip" is the original zip file from the issue.
        let zipFilePath = url(forResource: "prod-apple-swift-metrics-main-e6a00d36", withExtension: "zip")!
        let failDestinationPath = try autoRemovingSandbox()
        XCTAssertThrowsError(try Zip.unzipFile(zipFilePath, destination: failDestinationPath, overwrite: true))

        // "prod-apple-swift-metrics-main-e6a00d36-finder.zip" is a zip file
        // that was created by unzipping the original zip file with Finder on macOS 14.6.1
        // and then zipping it again using Finder on macOS 14.6.1.

        // "prod-apple-swift-metrics-main-e6a00d36-test.zip" is a zip file
        // that was created by unzipping the original zip file with Finder on macOS 14.6.1
        // and then zipping it again using vapor-community/Zip v2.2.0.
        let testZipFilePath = url(forResource: "prod-apple-swift-metrics-main-e6a00d36-test", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()
        XCTAssertNoThrow(try Zip.unzipFile(testZipFilePath, destination: destinationPath, overwrite: true))

        let destinationFolder = destinationPath.appendingPathComponent("prod-apple-swift-metrics-main-e6a00d36")
        XCTAssert(FileManager.default.fileExists(atPath: destinationFolder.appendingPathComponent("metadata.json").path))
        XCTAssert(FileManager.default.fileExists(atPath: destinationFolder.appendingPathComponent("main/index.html").path))
        XCTAssert(FileManager.default.fileExists(atPath: destinationFolder.appendingPathComponent("main/index/index.json").path))
        try XCTAssertGreaterThan(Data(contentsOf: destinationFolder.appendingPathComponent("metadata.json")).count, 0)

        let unzippedFiles = try FileManager.default.contentsOfDirectory(atPath: destinationFolder.path)

        let newZipFilePath = try autoRemovingSandbox().appendingPathComponent("new-archive.zip")
        try Zip.zipFiles(paths: [destinationFolder], zipFilePath: newZipFilePath)

        let newDestinationPath = try autoRemovingSandbox()
        try Zip.unzipFile(newZipFilePath, destination: newDestinationPath, overwrite: true)

        let newDestinationFolder = newDestinationPath.appendingPathComponent("prod-apple-swift-metrics-main-e6a00d36")
        XCTAssert(FileManager.default.fileExists(atPath: newDestinationFolder.appendingPathComponent("metadata.json").path))
        XCTAssert(FileManager.default.fileExists(atPath: newDestinationFolder.appendingPathComponent("main/index.html").path))
        XCTAssert(FileManager.default.fileExists(atPath: newDestinationFolder.appendingPathComponent("main/index/index.json").path))
        try XCTAssertGreaterThan(Data(contentsOf: newDestinationFolder.appendingPathComponent("metadata.json")).count, 0)

        let newUnzippedFiles = try FileManager.default.contentsOfDirectory(atPath: newDestinationFolder.path)
        XCTAssertEqual(unzippedFiles, newUnzippedFiles)
    }

    #if os(Windows)
        func testWindowsReservedChars() throws {
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

            let sandboxFolder = try autoRemovingSandbox()
            let zipFilePath = sandboxFolder.appendingPathComponent("archive.zip")
            try Zip.zipData(
                archiveFiles: [
                    txtFile, txtFile1, txtFile2, txtFile3, txtFile4, txtFile5, txtFile6, txtFile7,
                    file, file1, file2, file3,
                ],
                zipFilePath: zipFilePath
            )

            let destinationPath = try autoRemovingSandbox()
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

            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFileURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile1URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile2URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile3URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile4URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile5URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile6URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: txtFile7URL.path))

            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: file1URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: file2URL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: file3URL.path))
        }
    #endif
}
