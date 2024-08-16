//
//  ZipError.swift
//  Zip
//
//  Created by Francesco Paolo Severino on 16/08/2024.
//

/// Errors that can be thrown by Zip.
public struct ZipError: Error, Sendable {
    /// The type of the errors that can be thrown by Zip.
    public struct ErrorType: Sendable, Hashable, CustomStringConvertible {
        enum Base: String, Sendable {
            case fileNotFound
            case unzipFail
            case zipFail
        }

        let base: Base
        
        private init(_ base: Base) {
            self.base = base
        }

        /// File not found
        public static let fileNotFound = Self(.fileNotFound)
        /// Unzip fail
        public static let unzipFail = Self(.unzipFail)
        /// Zip fail
        public static let zipFail = Self(.zipFail)

        /// A textual representation of this error.
        public var description: String {
            base.rawValue
        }
    }

    private struct Backing: Sendable {
        fileprivate let errorType: ErrorType
        
        init(errorType: ErrorType) {
            self.errorType = errorType
        }
    }
    
    private var backing: Backing

    /// The type of this error.
    public var errorType: ErrorType { backing.errorType }

    private init(errorType: ErrorType) {
        self.backing = .init(errorType: errorType)
    }

    /// File not found
    public static let fileNotFound = Self(errorType: .fileNotFound)

    /// Unzip fail
    public static let unzipFail = Self(errorType: .unzipFail)

    /// Zip fail
    public static let zipFail = Self(errorType: .zipFail)
}

extension ZipError: CustomStringConvertible {
    public var description: String {
        "ZipError(errorType: \(self.errorType))"
    }
}