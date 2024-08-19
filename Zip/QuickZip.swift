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
     Get search path directory. For tvOS Documents directory doesn't exist.
     
     - returns: Search path directory
     */
    fileprivate class func searchPathDirectory() -> FileManager.SearchPathDirectory {
        var searchPathDirectory: FileManager.SearchPathDirectory = .documentDirectory
        
        #if os(tvOS)
            searchPathDirectory = .cachesDirectory
        #endif
        
        return searchPathDirectory
    }
    
    //MARK: Quick Unzip
    
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
       - progress: A progress closure called after unzipping each file in the archive. `Double` value between 0 and 1.
     
     - Throws: `ZipError.unzipFail` if unzipping fails or `ZipError.fileNotFound` if file is not found.
     
     > Note: Supports implicit progress composition.
     
     - Returns: `URL` of the destination folder.
     */
    public class func quickUnzipFile(_ path: URL, progress: ((_ progress: Double) -> ())?) throws -> URL {
        let fileManager = FileManager.default

        let fileExtension = path.pathExtension
        let fileName = path.lastPathComponent

        let directoryName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")

        #if os(Linux)
        // urls(for:in:) is not yet implemented on Linux
        // See https://github.com/apple/swift-corelibs-foundation/blob/swift-4.2-branch/Foundation/FileManager.swift#L125
        let documentsUrl = fileManager.temporaryDirectory
        #else
        let documentsUrl = fileManager.urls(for: self.searchPathDirectory(), in: .userDomainMask)[0]
        #endif
        do {
            let destinationUrl = documentsUrl.appendingPathComponent(directoryName, isDirectory: true)
            try self.unzipFile(path, destination: destinationUrl, overwrite: true, password: nil, progress: progress)
            return destinationUrl
        }catch{
            throw(ZipError.unzipFail)
        }
    }
    
    //MARK: Quick Zip
    
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
       - progress: A progress closure called after unzipping each file in the archive. `Double` value between 0 and 1.
     
     - Throws: `ZipError.zipFail` if zipping fails.
     
     > Note: Supports implicit progress composition.
     
     - Returns: `URL` of the destination folder.
     */
    public class func quickZipFiles(_ paths: [URL], fileName: String, progress: ((_ progress: Double) -> ())?) throws -> URL {
        let fileManager = FileManager.default
        #if os(Linux)
        // urls(for:in:) is not yet implemented on Linux
        // See https://github.com/apple/swift-corelibs-foundation/blob/swift-4.2-branch/Foundation/FileManager.swift#L125
        let documentsUrl = fileManager.temporaryDirectory
        #else
        let documentsUrl = fileManager.urls(for: self.searchPathDirectory(), in: .userDomainMask)[0] as URL
        #endif
        let destinationUrl = documentsUrl.appendingPathComponent("\(fileName).zip")
        try self.zipFiles(paths: paths, zipFilePath: destinationUrl, password: nil, progress: progress)
        return destinationUrl
    }
}
