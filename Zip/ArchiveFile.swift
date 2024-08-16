//
//  ArchiveFile.swift
//  Zip
//
//  Created by Francesco Paolo Severino on 16/08/2024.
//

import Foundation
@_implementationOnly import Minizip

/// Data in memory that will be archived as a file.
public struct ArchiveFile {
    var filename: String
    var data: Data
    var modifiedTime: Date?

    public init(filename: String, data: Data, modifiedTime: Date? = nil) {
        self.filename = filename
        self.data = data
        self.modifiedTime = modifiedTime
    }

    public init(filename: String, data: NSData, modifiedTime: Date? = nil) {
        self.filename = filename
        self.data = Data(referencing: data)
        self.modifiedTime = modifiedTime
    }
}

extension Zip {
    /**
     Zip data in memory.
     
     - parameter archiveFiles:Array of Archive Files.
     - parameter zipFilePath: Destination NSURL, should lead to a .zip filepath.
     - parameter password:    Password string. Optional.
     - parameter compression: Compression strategy
     - parameter progress: A progress closure called after unzipping each file in the archive. Double value betweem 0 and 1.
     
     - throws: Error if zipping fails.
     
     - notes: Supports implicit progress composition
     */
    public class func zipData(archiveFiles: [ArchiveFile], zipFilePath: URL, password: String?, compression: ZipCompression = .DefaultCompression, progress: ((_ progress: Double) -> ())?) throws {
        let destinationPath = zipFilePath.path

        // Progress handler set up
        var currentPosition: Int = 0
        var totalSize: Int = 0

        for archiveFile in archiveFiles {
            totalSize += archiveFile.data.count
        }

        let progressTracker = Progress(totalUnitCount: Int64(totalSize))
        progressTracker.isCancellable = false
        progressTracker.isPausable = false
        progressTracker.kind = ProgressKind.file

        // Begin Zipping
        let zip = zipOpen(destinationPath, APPEND_STATUS_CREATE)

        for archiveFile in archiveFiles {
            // Skip empty data
            if archiveFile.data.isEmpty {
                continue
            }

            // Setup the zip file info
            var zipInfo = zip_fileinfo(
                tmz_date: tm_zip(tm_sec: 0, tm_min: 0, tm_hour: 0, tm_mday: 0, tm_mon: 0, tm_year: 0),
                dosDate: 0,
                internal_fa: 0,
                external_fa: 0
            )

            if let modifiedTime = archiveFile.modifiedTime {
                let calendar = Calendar.current
                zipInfo.tmz_date.tm_sec = UInt32(calendar.component(.second, from: modifiedTime))
                zipInfo.tmz_date.tm_min = UInt32(calendar.component(.minute, from: modifiedTime))
                zipInfo.tmz_date.tm_hour = UInt32(calendar.component(.hour, from: modifiedTime))
                zipInfo.tmz_date.tm_mday = UInt32(calendar.component(.day, from: modifiedTime))
                zipInfo.tmz_date.tm_mon = UInt32(calendar.component(.month, from: modifiedTime))
                zipInfo.tmz_date.tm_year = UInt32(calendar.component(.year, from: modifiedTime))
            }

            // Write the data as a file to zip
            zipOpenNewFileInZip3(
                zip, archiveFile.filename, &zipInfo,
                nil, 0, nil, 0,
                nil,
                Z_DEFLATED,
                compression.minizipCompression,
                0,
                -MAX_WBITS,
                DEF_MEM_LEVEL,
                Z_DEFAULT_STRATEGY,
                password,
                0
            )
            let _ = archiveFile.data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                zipWriteInFileInZip(zip, bytes.baseAddress, UInt32(archiveFile.data.count))
            }
            zipCloseFileInZip(zip)

            // Update progress handler
            currentPosition += archiveFile.data.count

            if let progressHandler = progress{
                progressHandler((Double(currentPosition/totalSize)))
            }

            progressTracker.completedUnitCount = Int64(currentPosition)
        }

        zipClose(zip, nil)

        // Completed. Update progress handler.
        if let progressHandler = progress{
            progressHandler(1.0)
        }

        progressTracker.completedUnitCount = Int64(totalSize)
    }
}