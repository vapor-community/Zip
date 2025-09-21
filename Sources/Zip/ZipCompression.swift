private import CMinizip

/// Zip compression strategies.
public enum ZipCompression: Int {
    case NoCompression
    case BestSpeed
    case DefaultCompression
    case BestCompression

    internal var minizipCompression: Int32 {
        switch self {
        case .NoCompression: Z_NO_COMPRESSION
        case .BestSpeed: Z_BEST_SPEED
        case .DefaultCompression: Z_DEFAULT_COMPRESSION
        case .BestCompression: Z_BEST_COMPRESSION
        }
    }
}
