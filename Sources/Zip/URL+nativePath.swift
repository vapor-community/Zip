#if canImport(Darwin) || compiler(<6.0)
    import Foundation
#else
    import FoundationEssentials
#endif

extension URL {
    var nativePath: String {
        return withUnsafeFileSystemRepresentation { String(cString: $0!) }
    }
}
