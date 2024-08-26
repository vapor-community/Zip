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
        #if swift(>=6.0)
        let filePath = URL(fileURLWithPath: #file)
        #else
        let filePath = URL(fileURLWithPath: #filePath)
        #endif
        let resourcePath = filePath
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
        let destinationURL = try Zip.quickUnzipFile(filePath, progress: { progress in
            XCTAssertFalse(progress.isNaN)
        })
        addTeardownBlock {
            try? FileManager.default.removeItem(at: destinationURL)
        }
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
        let destinationURL = try Zip.quickZipFiles([imageURL1, imageURL2], fileName: "archive")
        XCTAssertTrue(FileManager.default.fileExists(atPath:destinationURL.path))
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
        XCTAssertTrue(FileManager.default.fileExists(atPath:destinationURL.path))
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
        let expectedPermissions = 0o644
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
        XCTAssertEqual(attributes777[.posixPermissions] as? Int, 0o777)
        XCTAssertEqual(attributes600[.posixPermissions] as? Int, 0o600)
        XCTAssertEqual(attributes604[.posixPermissions] as? Int, 0o604)
    }

    // Tests if https://github.com/marmelroy/Zip/issues/245 does not uccor anymore.
    func testUnzipProtectsAgainstPathTraversal() throws {
        let filePath = url(forResource: "pathTraversal", withExtension: "zip")!
        let destinationPath = try autoRemovingSandbox()

        do {
            try Zip.unzipFile(filePath, destination: destinationPath, overwrite: true, password: "password", progress: nil)
            XCTFail("ZipError.unzipFail expected.")
        } catch {}
        
        let fileManager = FileManager.default
        XCTAssertFalse(fileManager.fileExists(atPath: destinationPath.appendingPathComponent("../naughtyFile.txt").path))
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
        XCTAssertEqual(0b10000011001100011000110000110001, Date(timeIntervalSince1970: 2389282415).dosDate)
        XCTAssertEqual(0b00000001001100011000110000110001, Date(timeIntervalSince1970: 338060015).dosDate)
        XCTAssertEqual(0b00000000001000010000000000000000, Date(timeIntervalSince1970: 315532800).dosDate)
    }

    func testInit() {
        var zip: Zip? = Zip()
        XCTAssertNotNil(zip)
        zip = nil
        XCTAssertNil(zip)
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
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: destinationFolder.appendingPathComponent("metadata.json").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: destinationFolder.appendingPathComponent("main/index.html").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: destinationFolder.appendingPathComponent("main/index/index.json").path
            )
        )

        let unzippedFiles = try FileManager.default.contentsOfDirectory(atPath: destinationFolder.path)

        let newZipFilePath = try autoRemovingSandbox().appendingPathComponent("new-archive.zip")
        try Zip.zipFiles(paths: [destinationFolder], zipFilePath: newZipFilePath)

        let newDestinationPath = try autoRemovingSandbox()
        try Zip.unzipFile(newZipFilePath, destination: newDestinationPath, overwrite: true)

        let newDestinationFolder = newDestinationPath.appendingPathComponent("prod-apple-swift-metrics-main-e6a00d36")
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: newDestinationFolder.appendingPathComponent("metadata.json").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: newDestinationFolder.appendingPathComponent("main/index.html").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: newDestinationFolder.appendingPathComponent("main/index/index.json").path
            )
        )

        let newUnzippedFiles = try FileManager.default.contentsOfDirectory(atPath: newDestinationFolder.path)
        XCTAssertEqual(unzippedFiles, newUnzippedFiles)
    }
}
