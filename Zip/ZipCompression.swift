//
//  ZipCompression.swift
//  Zip
//
//  Created by Francesco Paolo Severino on 16/08/2024.
//

@_implementationOnly import Minizip

public enum ZipCompression: Int {
    case NoCompression
    case BestSpeed
    case DefaultCompression
    case BestCompression

    internal var minizipCompression: Int32 {
        switch self {
        case .NoCompression:
            return Z_NO_COMPRESSION
        case .BestSpeed:
            return Z_BEST_SPEED
        case .DefaultCompression:
            return Z_DEFAULT_COMPRESSION
        case .BestCompression:
            return Z_BEST_COMPRESSION
        }
    }
}