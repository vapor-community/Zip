import Foundation

extension Zip {
    struct ProcessedFilePath {
        let filePathURL: URL
        let fileName: String?

        var filePath: String {
            filePathURL.withUnsafeFileSystemRepresentation { String(cString: $0!) }
        }
    }

    /// Process zip paths.
    ///
    /// - Parameter paths: Paths as `URL`.
    ///
    /// - Returns: Array of ``ProcessedFilePath`` structs.
    static func processZipPaths(_ paths: [URL]) -> [ProcessedFilePath] {
        var processedFilePaths = [ProcessedFilePath]()
        for pathURL in paths {
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(
                atPath: pathURL.withUnsafeFileSystemRepresentation { String(cString: $0!) },
                isDirectory: &isDirectory
            )

            if !isDirectory.boolValue {
                let processedPath = ProcessedFilePath(filePathURL: pathURL, fileName: pathURL.lastPathComponent)
                processedFilePaths.append(processedPath)
            } else {
                let directoryContents = Self.expandDirectoryFilePath(pathURL)
                processedFilePaths.append(contentsOf: directoryContents)
            }
        }
        return processedFilePaths
    }

    /// Expand directory contents and parse them into ``ProcessedFilePath`` structs.
    ///
    /// - Parameter directory: Path of folder as `URL`.
    ///
    /// - Returns: Array of ``ProcessedFilePath`` structs.
    private static func expandDirectoryFilePath(_ directory: URL) -> [ProcessedFilePath] {
        var processedFilePaths = [ProcessedFilePath]()
        if let enumerator = FileManager.default.enumerator(atPath: directory.withUnsafeFileSystemRepresentation { String(cString: $0!) }) {
            while let filePathComponent = enumerator.nextObject() as? String {
                let pathURL = directory.appendingPathComponent(filePathComponent)

                var isDirectory: ObjCBool = false
                _ = FileManager.default.fileExists(
                    atPath: pathURL.withUnsafeFileSystemRepresentation { String(cString: $0!) },
                    isDirectory: &isDirectory
                )

                if !isDirectory.boolValue {
                    let fileName = (directory.lastPathComponent as NSString).appendingPathComponent(filePathComponent)
                    let processedPath = ProcessedFilePath(filePathURL: pathURL, fileName: fileName)
                    processedFilePaths.append(processedPath)
                }
            }
        }
        return processedFilePaths
    }
}
