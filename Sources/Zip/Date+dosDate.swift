#if canImport(Darwin) || compiler(<6.0)
    import Foundation
#else
    import FoundationEssentials
#endif

extension Date {
    var dosDate: UInt32 {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        let year = UInt32(components.year! - 1980) << 25
        let month = UInt32(components.month!) << 21
        let day = UInt32(components.day!) << 16
        let hour = UInt32(components.hour!) << 11
        let minute = UInt32(components.minute!) << 5
        let second = UInt32(components.second!) >> 1

        return year | month | day | hour | minute | second
    }
}
