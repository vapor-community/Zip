//
//  QuickZip.swift
//  Zip
//
//  Created by Roy Marmelstein on 16/01/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

extension Zip { 
    // Get search path directory. For tvOS Documents directory doesn't exist.
    fileprivate class var searchPathDirectory: FileManager.SearchPathDirectory {
        #if os(tvOS)
        .cachesDirectory
        #else
        .documentDirectory
        #endif
    }

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
    public class func quickUnzipFile(_ path: URL, progress: ((_ progress: Double) -> ())? = nil) throws -> URL {
        let fileExtension = path.pathExtension
        let fileName = path.lastPathComponent
        let directoryName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
        let documentsUrl = FileManager.default.urls(for: self.searchPathDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(directoryName, isDirectory: true)
        try self.unzipFile(path, destination: destinationUrl, overwrite: true, password: nil, progress: progress)
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
    public class func quickZipFiles(_ paths: [URL], fileName: String, progress: ((_ progress: Double) -> ())? = nil) throws -> URL {
        let documentsUrl = FileManager.default.urls(for: self.searchPathDirectory, in: .userDomainMask)[0] as URL
        let destinationUrl = documentsUrl.appendingPathComponent("\(fileName).zip")
        try self.zipFiles(paths: paths, zipFilePath: destinationUrl, password: nil, progress: progress)
        return destinationUrl
    }
}
