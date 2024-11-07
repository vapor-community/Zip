import Foundation

extension FileManager {
    struct ProcessedFilePath {
        let filePathURL: URL
        let fileName: String?

        var filePath: String {
            filePathURL.nativePath
        }
    }

    /// Process zip paths.
    ///
    /// - Parameter roots: Paths as `URL`.
    ///
    /// - Returns: Array of ``ProcessedFilePath`` structs.
    static func fileSubPaths(from roots: [URL]) -> [ProcessedFilePath] {
        var processedFilePaths = [ProcessedFilePath]()
        for pathURL in roots {
            var isDirectory: ObjCBool = false
            _ = FileManager.default.fileExists(
                atPath: pathURL.nativePath,
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
        if let enumerator = FileManager.default.enumerator(atPath: directory.nativePath) {
            while let filePathComponent = enumerator.nextObject() as? String {
                let pathURL = directory.appendingPathComponent(filePathComponent)

                var isDirectory: ObjCBool = false
                _ = FileManager.default.fileExists(
                    atPath: pathURL.nativePath,
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
