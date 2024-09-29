import Foundation
@_implementationOnly import CMinizip

/// Defines data saved in memory that will be archived as a file.
public struct ArchiveFile {
    var filename: String
    var data: Data
    var modifiedTime: Date?

    /// Creates an ``ArchiveFile`` instance.
    ///
    /// - Parameters:
    ///   - filename: The name of the file represented by the data.
    ///   - data: The `Data` to be archived.
    ///   - modifiedTime: The optional last modification date of the file.
    public init(filename: String, data: Data, modifiedTime: Date? = nil) {
        self.filename = filename
        self.data = data
        self.modifiedTime = modifiedTime
    }

    /// Creates an ``ArchiveFile`` instance.
    ///
    /// - Parameters:
    ///   - filename: The name of the file represented by the data.
    ///   - data: The `NSData` to be archived.
    ///   - modifiedTime: The optional last modification date of the file.
    @available(*, deprecated, message: "Use the initializer that takes Foundation's `Data` instead.")
    public init(filename: String, data: NSData, modifiedTime: Date? = nil) {
        self.filename = filename
        self.data = Data(referencing: data)
        self.modifiedTime = modifiedTime
    }
}

extension Zip {
    /**
     Creates a zip file from an array of ``ArchiveFile``s
     
     - Parameters:
       - archiveFiles: Array of ``ArchiveFile``.
       - zipFilePath:  Destination `URL`, should lead to a `.zip` filepath.
       - password:     The optional password string.
       - compression:  The compression strategy to use.
       - progress:     A progress closure called after unzipping each file in the archive. Double value betweem 0 and 1.
     
     - Throws: `ZipError.zipFail` if zipping fails.
     
     > Note: Supports implicit progress composition.
     */
    public class func zipData(
        archiveFiles: [ArchiveFile],
        zipFilePath: URL,
        password: String? = nil,
        compression: ZipCompression = .DefaultCompression,
        progress: ((_ progress: Double) -> ())? = nil
    ) throws {
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
        let zip = zipOpen(zipFilePath.withUnsafeFileSystemRepresentation { String(cString: $0!) }, APPEND_STATUS_CREATE)

        for archiveFile in archiveFiles {
            // Skip empty data
            if archiveFile.data.isEmpty {
                continue
            }

            // Setup the zip file info
            var zipInfo = zip_fileinfo(
                dos_date: 0,
                internal_fa: 0,
                external_fa: 0
            )

            if let modifiedTime = archiveFile.modifiedTime {
                zipInfo.dos_date = modifiedTime.dosDate
            }

            // Write the data as a file to zip
            zipOpenNewFileInZip3(
                zip, archiveFile.filename, &zipInfo,
                nil, 0, nil, 0,
                nil,
                UInt16(Z_DEFLATED),
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

            if let progressHandler = progress {
                progressHandler((Double(currentPosition/totalSize)))
            }

            progressTracker.completedUnitCount = Int64(currentPosition)
        }

        zipClose(zip, nil)

        // Completed. Update progress handler.
        if let progressHandler = progress {
            progressHandler(1.0)
        }

        progressTracker.completedUnitCount = Int64(totalSize)
    }
}