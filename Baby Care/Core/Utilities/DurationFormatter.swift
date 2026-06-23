import Foundation

enum DurationFormatter {
    /// 7245 → "2 sa 0 dk"  ·  120 → "2 dk"  ·  35 → "35 sn"
    static func string(fromSeconds seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) sn"
        }
        let totalMinutes = seconds / 60
        if totalMinutes < 60 {
            return "\(totalMinutes) dk"
        }
        let hours = totalMinutes / 60
        let mins  = totalMinutes % 60
        return "\(hours) sa \(mins) dk"
    }
}
