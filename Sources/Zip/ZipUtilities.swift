//
//  ZipUtilities.swift
//  Zip
//
//  Created by Roy Marmelstein on 26/01/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

#if canImport(Darwin)
import Foundation
#else
import FoundationEssentials
#endif

internal class ZipUtilities {
    /*
     Include root directory.
     Default is true.
     
     e.g. The Test directory contains two files A.txt and B.txt.
     
     As true:
     $ zip -r Test.zip Test/
     $ unzip -l Test.zip
        Test/
        Test/A.txt
        Test/B.txt
     
     As false:
     $ zip -r Test.zip Test/
     $ unzip -l Test.zip
        A.txt
        B.txt
    */
    let includeRootDirectory = true

    /**
     *  ProcessedFilePath struct
     */
    internal struct ProcessedFilePath {
        let filePathURL: URL
        let fileName: String?
        
        var filePath: String {
            filePathURL.path
        }
    }
    
    // MARK: Path processing
    
    /**
     Process zip paths
    
     - Parameter paths: Paths as `URL`.
    
     - Returns: Array of `ProcessedFilePath` structs.
    */
    internal func processZipPaths(_ paths: [URL]) -> [ProcessedFilePath] {
        var processedFilePaths = [ProcessedFilePath]()
        for pathURL in paths {
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(atPath: pathURL.path, isDirectory: &isDirectory)
            if !isDirectory.boolValue {
                let processedPath = ProcessedFilePath(filePathURL: pathURL, fileName: pathURL.lastPathComponent)
                processedFilePaths.append(processedPath)
            } else {
                let directoryContents = expandDirectoryFilePath(pathURL)
                processedFilePaths.append(contentsOf: directoryContents)
            }
        }
        return processedFilePaths
    }
    
    /**
      Expand directory contents and parse them into `ProcessedFilePath` structs.
     
      - Parameter directory: Path of folder as `URL`.
     
      - Returns: Array of `ProcessedFilePath` structs.
     */
    internal func expandDirectoryFilePath(_ directory: URL) -> [ProcessedFilePath] {
        var processedFilePaths = [ProcessedFilePath]()
        if let enumerator = FileManager.default.enumerator(atPath: directory.path) {
            while let filePathComponent = enumerator.nextObject() as? String {
                let pathURL = directory.appendingPathComponent(filePathComponent)
                var isDirectory: ObjCBool = false
                _ = FileManager.default.fileExists(atPath: pathURL.path, isDirectory: &isDirectory)
                if !isDirectory.boolValue {
                    var fileName = filePathComponent
                    if includeRootDirectory {
                        fileName = (directory.lastPathComponent as NSString).appendingPathComponent(filePathComponent)
                    }
                    let processedPath = ProcessedFilePath(filePathURL: pathURL, fileName: fileName)
                    processedFilePaths.append(processedPath)
                }
            }
        }
        return processedFilePaths
    }
}
