//
//  Zip.swift
//  Zip
//
//  Created by Roy Marmelstein on 13/12/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

private import CMinizip
import Foundation

/// Main class that handles zipping and unzipping of files.
public class Zip {
    // Set of vaild file extensions
    nonisolated(unsafe) private static var customFileExtensions: Set<String> = []
    private static let lock = NSLock()

    @available(*, deprecated, message: "Do not use this initializer. Zip is a utility class and should not be instantiated.")
    public init() {}

    /// Unzips a file.
    ///
    /// - Parameters:
    ///   - zipFilePath: Local file path of zipped file.
    ///   - destination: Local file path to unzip to.
    ///   - overwrite: Indicates whether or not to overwrite files at the destination path.
    ///   - password: Optional password if file is protected.
    ///   - progress: A progress closure called after unzipping each file in the archive. A `Double` value between 0 and 1.
    ///   - fileOutputHandler: A closure called after each file is unzipped. A `URL` value of the unzipped file.
    ///
    /// - Throws: ``ZipError/unzipFail`` if unzipping fails or if fail is not found.
    ///
    /// > Note: Supports implicit progress composition.
    public class func unzipFile(
        _ zipFilePath: URL,
        destination: URL,
        overwrite: Bool = true,
        password: String? = nil,
        progress: ((_ progress: Double) -> Void)? = nil,
        fileOutputHandler: ((_ unzippedFile: URL) -> Void)? = nil
    ) throws {
        // Check whether a zip file exists at path.
        let path = zipFilePath.nativePath
        if !FileManager.default.fileExists(atPath: path) || !isValidFileExtension(zipFilePath.pathExtension) {
            throw ZipError.fileNotFound
        }

        // Progress handler set up
        var totalSize: Double = 0.0
        var currentPosition: Double = 0.0
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: path)
        if let attributeFileSize = fileAttributes[FileAttributeKey.size] as? Double {
            totalSize += attributeFileSize
        }

        let progressTracker = Progress(totalUnitCount: Int64(totalSize))
        progressTracker.isCancellable = false
        progressTracker.isPausable = false
        progressTracker.kind = ProgressKind.file

        // Begin unzipping
        let zip = unzOpen64(path)
        defer { unzClose(zip) }
        if unzGoToFirstFile(zip) != UNZ_OK {
            throw ZipError.unzipFail
        }

        #if os(Windows)
            var fileNames = Set<String>()
        #endif

        var buffer = [CUnsignedChar](repeating: 0, count: 4096)
        var result: Int32

        repeat {
            if let cPassword = password?.cString(using: String.Encoding.ascii) {
                guard unzOpenCurrentFilePassword(zip, cPassword) == UNZ_OK else {
                    throw ZipError.unzipFail
                }
            } else {
                guard unzOpenCurrentFile(zip) == UNZ_OK else {
                    throw ZipError.unzipFail
                }
            }

            var fileInfo = unz_file_info64()
            guard unzGetCurrentFileInfo64(zip, &fileInfo, nil, 0, nil, 0, nil, 0) == UNZ_OK else {
                unzCloseCurrentFile(zip)
                throw ZipError.unzipFail
            }

            currentPosition += Double(fileInfo.compressed_size)

            let fileNameSize = Int(fileInfo.size_filename) + 1
            let fileName = UnsafeMutablePointer<CChar>.allocate(capacity: fileNameSize)
            defer { fileName.deallocate() }

            unzGetCurrentFileInfo64(zip, &fileInfo, fileName, UInt16(fileNameSize), nil, 0, nil, 0)
            fileName[Int(fileInfo.size_filename)] = 0

            var pathString = String(cString: fileName)

            #if os(Windows)
                // Windows Reserved Characters
                let reservedCharacters: CharacterSet = ["<", ">", ":", "\"", "|", "?", "*"]

                if pathString.rangeOfCharacter(from: reservedCharacters) != nil {
                    pathString = pathString.components(separatedBy: reservedCharacters).joined(separator: "_")

                    let pathExtension = (pathString as NSString).pathExtension
                    let pathWithoutExtension = (pathString as NSString).deletingPathExtension
                    var counter = 1
                    while fileNames.contains(pathString) {
                        let newFileName = "\(pathWithoutExtension) (\(counter))"
                        pathString = pathExtension.isEmpty ? newFileName : newFileName.appendingPathExtension(pathExtension) ?? newFileName
                        counter += 1
                    }
                }

                fileNames.insert(pathString)
            #endif

            guard !pathString.isEmpty else {
                throw ZipError.unzipFail
            }

            if pathString.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\")) != nil {
                pathString = pathString.replacingOccurrences(of: "\\", with: "/")
            }

            let fullPath = destination.appendingPathComponent(pathString).standardizedFileURL.nativePath

            // `.standardizedFileURL` removes any `..` to move a level up.
            // If we then check that the `fullPath` starts with the destination directory we know we are not extracting "outside" the destination.
            guard fullPath.starts(with: destination.standardizedFileURL.nativePath) else {
                throw ZipError.unzipFail
            }

            let directoryAttributes: [FileAttributeKey: Any]?
            #if (os(Linux) || os(Windows)) && compiler(<6.0)
                directoryAttributes = nil
            #else
                let creationDate = Date()
                directoryAttributes = [
                    .creationDate: creationDate,
                    .modificationDate: creationDate,
                ]
            #endif

            let isDirectory =
                fileName[Int(fileInfo.size_filename - 1)] == "/".cString(using: String.Encoding.utf8)?.first
                || fileName[Int(fileInfo.size_filename - 1)] == "\\".cString(using: String.Encoding.utf8)?.first

            do {
                try FileManager.default.createDirectory(
                    atPath: (fullPath as NSString).deletingLastPathComponent,
                    withIntermediateDirectories: true,
                    attributes: directoryAttributes
                )

                if isDirectory {
                    try FileManager.default.createDirectory(
                        atPath: fullPath,
                        withIntermediateDirectories: false,
                        attributes: directoryAttributes
                    )
                }
            } catch {}

            if FileManager.default.fileExists(atPath: fullPath) && !isDirectory && !overwrite {
                unzCloseCurrentFile(zip)
                unzGoToNextFile(zip)
            }

            var writeBytes: UInt64 = 0
            let filePointer = fopen(fullPath, "wb")
            while let filePointer {
                let readBytes = unzReadCurrentFile(zip, &buffer, UInt32(buffer.count))
                guard readBytes > 0 else { break }
                guard fwrite(buffer, Int(readBytes), 1, filePointer) == 1 else {
                    throw ZipError.unzipFail
                }
                writeBytes += UInt64(readBytes)
            }

            if let filePointer { fclose(filePointer) }

            guard unzCloseCurrentFile(zip) != UNZ_CRCERROR else {
                throw ZipError.unzipFail
            }

            guard writeBytes == fileInfo.uncompressed_size else {
                throw ZipError.unzipFail
            }

            // Set file permissions from current `fileInfo`
            if fileInfo.external_fa != 0 {
                let permissions = (fileInfo.external_fa >> 16) & 0x1FF
                // We will define a valid permission range between Owner read only to full access
                if permissions >= 0o400 && permissions <= 0o777 {
                    do {
                        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: fullPath)
                    } catch {
                        print("Failed to set permissions to file \(fullPath), error: \(error)")
                    }
                }
            }

            result = unzGoToNextFile(zip)

            // Update progress handler
            if let progress {
                progress(currentPosition / totalSize)
            }

            if let fileOutputHandler {
                fileOutputHandler(URL(fileURLWithPath: fullPath, isDirectory: false))
            }

            progressTracker.completedUnitCount = Int64(currentPosition)
        } while result == UNZ_OK && result != UNZ_END_OF_LIST_OF_FILE

        // Completed. Update progress handler.
        if let progress {
            progress(1.0)
        }
        progressTracker.completedUnitCount = Int64(totalSize)
    }

    /// Zips a group of files.
    ///
    /// - Parameters:
    ///   - paths: Array of `URL` filepaths.
    ///   - zipFilePath: Destination `URL`, should lead to a `.zip` filepath.
    ///   - password: The optional password string.
    ///   - compression: The compression strategy to use.
    ///   - progress: A progress closure called after unzipping each file in the archive. A `Double` value between 0 and 1.
    ///
    /// - Throws: ``ZipError/zipFail`` if zipping fails.
    ///
    /// > Note: Supports implicit progress composition.
    public class func zipFiles(
        paths: [URL],
        zipFilePath: URL,
        password: String? = nil,
        compression: ZipCompression = .DefaultCompression,
        progress: ((_ progress: Double) -> Void)? = nil
    ) throws {
        let processedPaths = FileManager.fileSubPaths(from: paths)

        let chunkSize = 16384

        // Progress handler set up
        var currentPosition = 0.0
        var totalSize = 0.0
        // Get `totalSize` for progress handler
        for path in processedPaths {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: path.filePath)
                if let fileSize = fileAttributes[FileAttributeKey.size] as? Double {
                    totalSize += fileSize
                }
            } catch {}
        }

        let progressTracker = Progress(totalUnitCount: Int64(totalSize))
        progressTracker.isCancellable = false
        progressTracker.isPausable = false
        progressTracker.kind = ProgressKind.file

        // Begin Zipping
        let zip = zipOpen(zipFilePath.nativePath, APPEND_STATUS_CREATE)

        for path in processedPaths {
            let filePath = path.filePath

            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
            if !isDirectory.boolValue {
                guard let input = fopen(filePath, "r") else {
                    throw ZipError.zipFail
                }
                defer { fclose(input) }

                var zipInfo: zip_fileinfo = zip_fileinfo(dos_date: 0, internal_fa: 0, external_fa: 0)

                do {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
                    if let fileDate = fileAttributes[FileAttributeKey.modificationDate] as? Date {
                        zipInfo.dos_date = fileDate.dosDate
                    }
                    if let fileSize = fileAttributes[FileAttributeKey.size] as? Double {
                        currentPosition += fileSize
                    }
                } catch {}

                let buffer = UnsafeMutableRawPointer.allocate(byteCount: chunkSize, alignment: 1)
                defer { buffer.deallocate() }

                if let fileName = path.fileName {
                    zipOpenNewFileInZip3(
                        zip, fileName, &zipInfo,
                        nil, 0, nil, 0, nil,
                        UInt16(Z_DEFLATED), compression.minizipCompression, 0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                        password, 0
                    )
                } else {
                    throw ZipError.zipFail
                }

                while feof(input) == 0 {
                    zipWriteInFileInZip(
                        zip,
                        buffer,
                        UInt32(fread(buffer, 1, chunkSize, input))
                    )
                }

                // Update progress handler, only if progress is not 1,
                // because if we call it when progress == 1,
                // the user will receive a progress handler call with value 1.0 twice.
                if let progress, currentPosition / totalSize != 1 {
                    progress(currentPosition / totalSize)
                }
                progressTracker.completedUnitCount = Int64(currentPosition)

                zipCloseFileInZip(zip)
            }
        }

        zipClose(zip, nil)

        // Completed. Update progress handler.
        if let progress {
            progress(1.0)
        }
        progressTracker.completedUnitCount = Int64(totalSize)
    }

    /// Adds a file extension to the set of custom file extensions.
    ///
    /// - Parameter fileExtension: A file extension.
    public class func addCustomFileExtension(_ fileExtension: String) {
        lock.lock()
        customFileExtensions.insert(fileExtension)
        lock.unlock()
    }

    /// Removes a file extension from the set of custom file extensions.
    ///
    /// - Parameter fileExtension: A file extension.
    public class func removeCustomFileExtension(_ fileExtension: String) {
        lock.lock()
        customFileExtensions.remove(fileExtension)
        lock.unlock()
    }

    /// Checks if a specific file extension is valid.
    ///
    /// - Parameter fileExtension: A file extension to check.
    ///
    /// - Returns: `true` if the extension is valid, otherwise `false`.
    public class func isValidFileExtension(_ fileExtension: String) -> Bool {
        lock.lock()
        let validFileExtensions = customFileExtensions.union(["zip", "cbz"])
        lock.unlock()
        return validFileExtensions.contains(fileExtension)
    }
}
