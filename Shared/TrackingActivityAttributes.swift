#if os(iOS)
import ActivityKit
import Foundation

/// Devam eden emzirme veya uyku için Live Activity.
/// Her devam eden kayıt için en fazla bir aktivite açılır (`recordID` ile eşlenir).
nonisolated struct TrackingActivityAttributes: ActivityAttributes {
    enum Kind: String, Codable, Hashable, Sendable {
        case feeding
        case sleep
    }

    struct ContentState: Codable, Hashable, Sendable {
        var startedAt: Date
        /// "Sol göğüs", "Gündüz uykusu" gibi.
        var detail: String
    }

    var kind: Kind
    var recordID: UUID
    var babyName: String
}
#endif
