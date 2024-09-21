//
//  Zip.swift
//  Zip
//
//  Created by Roy Marmelstein on 13/12/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

#if swift(>=6.0)
import FoundationEssentials
#else
import Foundation
#endif
@_implementationOnly import CMinizip

/// Main class that handles zipping and unzipping of files.
public class Zip {
    // Set of vaild file extensions
    internal static var customFileExtensions: Set<String> = []

    @available(*, deprecated, message: "Do not use this initializer. Zip is a utility class and should not be instantiated.")
    public init () {}
    
    /**
     Unzips a file.
     
     - Parameters:
       - zipFilePath: Local file path of zipped file.
       - destination: Local file path to unzip to.
       - overwrite:   Indicates whether or not to overwrite files at the destination path.
       - password:    Optional password if file is protected.
       - progress:    A progress closure called after unzipping each file in the archive. A `Double` value between 0 and 1.
       - fileOutputHandler: A closure called after each file is unzipped. A `URL` value of the unzipped file.

     - Throws: `ZipError.unzipFail` if unzipping fails or if fail is not found.
     
     > Note: Supports implicit progress composition
     */
    public class func unzipFile(
        _ zipFilePath: URL,
        destination: URL,
        overwrite: Bool = true,
        password: String? = nil,
        progress: ((_ progress: Double) -> ())? = nil,
        fileOutputHandler: ((_ unzippedFile: URL) -> Void)? = nil
    ) throws {
        // Check whether a zip file exists at path.
        let path = zipFilePath.path
        if FileManager.default.fileExists(atPath: path) == false || !isValidFileExtension(zipFilePath.pathExtension) {
            throw ZipError.fileNotFound
        }
        
        // Unzip set up
        var ret: Int32 = 0
        let bufferSize: UInt32 = 4096
        var buffer = Array<CUnsignedChar>(repeating: 0, count: Int(bufferSize))
        
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
            print("XXXXXXXXXXXXX - 1")
            throw ZipError.unzipFail
        }
        repeat {
            if let cPassword = password?.cString(using: String.Encoding.ascii) {
                ret = unzOpenCurrentFilePassword(zip, cPassword)
            } else {
                ret = unzOpenCurrentFile(zip)
            }
            if ret != UNZ_OK {
                print("XXXXXXXXXXXXX - 2")
                throw ZipError.unzipFail
            }
            var fileInfo = unz_file_info64()
            ret = unzGetCurrentFileInfo64(zip, &fileInfo, nil, 0, nil, 0, nil, 0)
            if ret != UNZ_OK {
                unzCloseCurrentFile(zip)
                print("XXXXXXXXXXXXX - 3")
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
            // Colons are not allowed in Windows file names.
            pathString = pathString.replacingOccurrences(of: ":", with: "_")
            #endif

            guard !pathString.isEmpty else {
                print("XXXXXXXXXXXXX - 4")
                throw ZipError.unzipFail
            }

            let fileInfoSizeFileName = Int(fileInfo.size_filename - 1)
            let isDirectory = fileName[fileInfoSizeFileName] == "/".cString(using: String.Encoding.utf8)?.first || fileName[fileInfoSizeFileName] == "\\".cString(using: String.Encoding.utf8)?.first
            if pathString.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\")) != nil {
                pathString = pathString.replacingOccurrences(of: "\\", with: "/")
            }

            let fullPath = destination.appendingPathComponent(pathString).standardizedFileURL.path
            // `.standardizedFileURL` removes any `..` to move a level up.
            // If we then check that the `fullPath` starts with the destination directory we know we are not extracting "outside" the destination.
            guard fullPath.starts(with: destination.standardizedFileURL.path) else {
                print("XXXXXXXXXXXXX - 5")
                throw ZipError.unzipFail
            }

            let directoryAttributes: [FileAttributeKey: Any]?
            #if (os(Linux) || os(Windows)) && swift(<6.0)
                // On Linux and Windows, setting attributes is not yet really implemented.
                directoryAttributes = nil
            #else
                let creationDate = Date()
                directoryAttributes = [
                    .creationDate: creationDate,
                    .modificationDate: creationDate
                ]
            #endif

            do {
                if isDirectory {
                    try FileManager.default.createDirectory(atPath: fullPath, withIntermediateDirectories: true, attributes: directoryAttributes)
                } else {
                    let parentDirectory = (fullPath as NSString).deletingLastPathComponent
                    try FileManager.default.createDirectory(atPath: parentDirectory, withIntermediateDirectories: true, attributes: directoryAttributes)
                }
            } catch {}
            if FileManager.default.fileExists(atPath: fullPath) && !isDirectory && !overwrite {
                unzCloseCurrentFile(zip)
                ret = unzGoToNextFile(zip)
            }

            var writeBytes: UInt64 = 0
            let filePointer: UnsafeMutablePointer<FILE>? = fopen(fullPath, "wb")
            while let filePointer {
                let readBytes = unzReadCurrentFile(zip, &buffer, bufferSize)
                guard readBytes > 0 else { break }
                guard fwrite(buffer, Int(readBytes), 1, filePointer) == 1 else {
                    print("XXXXXXXXXXXXX - 6")
                    throw ZipError.unzipFail
                }
                writeBytes += UInt64(readBytes)
            }

            if let filePointer { fclose(filePointer) }

            if unzCloseCurrentFile(zip) == UNZ_CRCERROR {
                print("XXXXXXXXXXXXX - 7")
                throw ZipError.unzipFail
            }
            guard writeBytes == fileInfo.uncompressed_size else {
                print("XXXXXXXXXXXXX - 8")
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

            ret = unzGoToNextFile(zip)
            
            // Update progress handler
            if let progressHandler = progress {
                progressHandler((currentPosition / totalSize))
            }
            
            if let fileHandler = fileOutputHandler,
                let encodedString = fullPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                #if os(Windows)
                let fileUrlString = "file:///\(encodedString)"
                #else
                let fileUrlString = encodedString
                #endif
                if let fileUrl = URL(string: fileUrlString) {
                    fileHandler(fileUrl)
                }
            }
            
            progressTracker.completedUnitCount = Int64(currentPosition)
        } while (ret == UNZ_OK && ret != UNZ_END_OF_LIST_OF_FILE)
        
        // Completed. Update progress handler.
        if let progressHandler = progress {
            progressHandler(1.0)
        }

        progressTracker.completedUnitCount = Int64(totalSize)
    }
    
    /**
     Zips a group of files.
     
     - Parameters:
       - paths:       Array of `URL` filepaths.
       - zipFilePath: Destination `URL`, should lead to a `.zip` filepath.
       - password:    The optional password string.
       - compression: The compression strategy to use.
       - progress:    A progress closure called after unzipping each file in the archive. A `Double` value between 0 and 1.

     - Throws: `ZipError.zipFail` if zipping fails.
     
     > Note: Supports implicit progress composition
     */
    public class func zipFiles(
        paths: [URL],
        zipFilePath: URL,
        password: String? = nil,
        compression: ZipCompression = .DefaultCompression,
        progress: ((_ progress: Double) -> ())? = nil
    ) throws {
        let processedPaths = ZipUtilities().processZipPaths(paths)
        
        // Zip set up
        let chunkSize: Int = 16384
        
        // Progress handler set up
        var currentPosition: Double = 0.0
        var totalSize: Double = 0.0
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
        let zip = zipOpen(zipFilePath.path, APPEND_STATUS_CREATE)
        for path in processedPaths {
            let filePath = path.filePath
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
            if !isDirectory.boolValue {
                guard let input = fopen(filePath, "r") else {
                    throw ZipError.zipFail
                }
                defer { fclose(input) }
                let fileName = path.fileName
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
                guard let buffer = malloc(chunkSize) else {
                    throw ZipError.zipFail
                }
                if let password, let fileName {
                    zipOpenNewFileInZip3(
                        zip, fileName, &zipInfo,
                        nil, 0, nil, 0, nil,
                        UInt16(Z_DEFLATED), compression.minizipCompression, 0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                        password, 0
                    )
                } else if let fileName {
                    zipOpenNewFileInZip3(
                        zip, fileName, &zipInfo,
                        nil, 0, nil, 0, nil,
                        UInt16(Z_DEFLATED), compression.minizipCompression, 0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
                        nil, 0
                    )
                } else {
                    throw ZipError.zipFail
                }
                var length: Int = 0
                while feof(input) == 0 {
                    length = fread(buffer, 1, chunkSize, input)
                    zipWriteInFileInZip(zip, buffer, UInt32(length))
                }
                
                // Update progress handler, only if progress is not 1,
                // because if we call it when progress == 1,
                // the user will receive a progress handler call with value 1.0 twice.
                if let progressHandler = progress, currentPosition / totalSize != 1 {
                    progressHandler(currentPosition / totalSize)
                }

                progressTracker.completedUnitCount = Int64(currentPosition)
                
                zipCloseFileInZip(zip)
                free(buffer)
            }
        }
        zipClose(zip, nil)
        
        // Completed. Update progress handler.
        if let progressHandler = progress{
            progressHandler(1.0)
        }
        
        progressTracker.completedUnitCount = Int64(totalSize)
    }
    
    /**
     Adds a file extension to the set of custom file extensions.
     
     - Parameter fileExtension: A file extension.
     */
    public class func addCustomFileExtension(_ fileExtension: String) {
        customFileExtensions.insert(fileExtension)
    }
    
    /**
     Removes a file extension from the set of custom file extensions.
     
     - Parameter fileExtension: A file extension.
     */
    public class func removeCustomFileExtension(_ fileExtension: String) {
        customFileExtensions.remove(fileExtension)
    }
    
    /**
     Checks if a specific file extension is valid.
     
     - Parameter fileExtension: A file extension to check.
     
     - Returns: `true` if the extension is valid, otherwise `false`.
     */
    public class func isValidFileExtension(_ fileExtension: String) -> Bool {
        let validFileExtensions: Set<String> = customFileExtensions.union(["zip", "cbz"])
        return validFileExtensions.contains(fileExtension)
    }
}
