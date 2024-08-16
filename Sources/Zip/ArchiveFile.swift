//
//  ArchiveFile.swift
//  Zip
//
//  Created by Francesco Paolo Severino on 16/08/2024.
//

import Foundation

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
}