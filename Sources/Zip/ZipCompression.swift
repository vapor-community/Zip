@_implementationOnly import CMinizip

/// Zip compression strategies.
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
