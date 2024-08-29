//
//  QuickZip.swift
//  Zip
//
//  Created by Roy Marmelstein on 16/01/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

extension Zip { 
    /**
     Quickly unzips a file.
     
     Unzips to a new folder inside the app's documents folder with the zip file's name.
     
     - Parameter path: Path of zipped file.
     
     - Throws: `ZipError.unzipFail` if unzipping fails or `ZipError.fileNotFound` if file is not found.
     
     - Returns: `URL` of the destination folder.
     */
    public class func quickUnzipFile(_ path: URL) throws -> URL {
        return try quickUnzipFile(path, progress: nil)
    }
    
    /**
     Quickly unzips a file.
     
     Unzips to a new folder inside the app's documents folder with the zip file's name.
     
     - Parameters:
       - path: Path of zipped file.
       - progress: An optional progress closure called after unzipping each file in the archive. A `Double` value between 0 and 1.
     
     - Throws: `ZipError.unzipFail` if unzipping fails or `ZipError.fileNotFound` if file is not found.
     
     > Note: Supports implicit progress composition.
     
     - Returns: `URL` of the destination folder.
     */
    public class func quickUnzipFile(_ path: URL, progress: ((_ progress: Double) -> ())?) throws -> URL {
        let destinationUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent(path.deletingPathExtension().lastPathComponent, isDirectory: true)
        try self.unzipFile(path, destination: destinationUrl, progress: progress)
        return destinationUrl
    }

    /**
     Quickly zips files.
     
     - Parameters:
       - paths: Array of `URL` filepaths.
       - fileName: File name for the resulting zip file.
     
     - Throws: `ZipError.zipFail` if zipping fails.
     
     > Note: Supports implicit progress composition.
     
     - Returns: `URL` of the destination folder.
     */
    public class func quickZipFiles(_ paths: [URL], fileName: String) throws -> URL {
        return try quickZipFiles(paths, fileName: fileName, progress: nil)
    }
    
    /**
     Quickly zips files.
     
     - Parameters:
       - paths: Array of `URL` filepaths.
       - fileName: File name for the resulting zip file.
       - progress: An optional progress closure called after unzipping each file in the archive. A `Double` value between 0 and 1.
     
     - Throws: `ZipError.zipFail` if zipping fails.
     
     > Note: Supports implicit progress composition.
     
     - Returns: `URL` of the destination folder.
     */
    public class func quickZipFiles(_ paths: [URL], fileName: String, progress: ((_ progress: Double) -> ())?) throws -> URL {
        var fileNameWithExtension = fileName
        if !fileName.hasSuffix(".zip") {
            fileNameWithExtension += ".zip"
        }

        print("fileNameWithExtension: \(fileNameWithExtension)")

        let destinationUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileNameWithExtension)
        try self.zipFiles(paths: paths, zipFilePath: destinationUrl, progress: progress)
        return destinationUrl
    }
}
