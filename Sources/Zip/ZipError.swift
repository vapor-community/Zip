#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Errors that can be thrown by Zip.
public enum ZipError: Error {
    /// The file was not found
    case fileNotFound
    /// Unzip failure
    case unzipFail
    /// Zip failure
    case zipFail

    /// A textual representation of this error.
    public var description: String {
        switch self {
        case .fileNotFound: "File not found."
        case .unzipFail: "Failed to unzip file."
        case .zipFail: "Failed to zip file."
        }
    }
}
