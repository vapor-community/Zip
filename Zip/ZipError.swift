//
//  ZipError.swift
//  Zip
//
//  Created by Francesco Paolo Severino on 16/08/2024.
//

import Foundation

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
        case .fileNotFound: return NSLocalizedString("File not found.", comment: "")
        case .unzipFail: return NSLocalizedString("Failed to unzip file.", comment: "")
        case .zipFail: return NSLocalizedString("Failed to zip file.", comment: "")
        }
    }
}
