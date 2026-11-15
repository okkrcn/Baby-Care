import Foundation

/// Uygulama ile widget uzantısının paylaştığı App Group.
nonisolated enum AppGroup {
    static let identifier = "group.okkrcn.Baby-Care"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

/// Widget'ların gösterdiği özet. Uygulama her kayıttan sonra yeniden yazar.
///
/// Widget uzantısı SwiftData veritabanını açmaz; yalnızca bu küçük özeti okur.
/// Böylece veritabanı uygulamanın kendi kapsayıcısında kalır ve mevcut
/// kullanıcı verisinin taşınması gerekmez.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    /// Devam eden emzirme veya uyku.
    struct Ongoing: Codable, Equatable, Sendable {
        var recordID: UUID
        var startedAt: Date
        /// "Sol göğüs", "Gündüz uykusu" gibi kısa açıklama.
        var detail: String
    }

    var babyName: String
    /// "4 aylık", "3 haftalık" gibi.
    var ageText: String

    /// Son beslenmenin başlangıç zamanı (devam eden dahil değil).
    var lastFeedingAt: Date?
    /// "Biberon · 90 ml", "Emzirme · 12 dk" gibi.
    var lastFeedingDetail: String?
    var ongoingFeeding: Ongoing?

    /// Son tamamlanan uykunun bitiş zamanı.
    var lastSleepEndedAt: Date?
    var ongoingSleep: Ongoing?

    var lastDiaperAt: Date?
    /// "Çiş", "Kaka", "Karışık".
    var lastDiaperType: String?

    var generatedAt: Date
}

/// Özetin App Group'taki deposu.
nonisolated enum WidgetSnapshotStore {
    static let key = "widgetSnapshot.v1"

    static func load(from defaults: UserDefaults? = AppGroup.defaults) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Özeti yazar. Hiç bebek yoksa `nil` ile çağrılır ve kayıt silinir.
    /// - Returns: Kayıtlı özet değiştiyse `true` (widget yenilemesi gerekir).
    @discardableResult
    static func save(_ snapshot: WidgetSnapshot?, to defaults: UserDefaults? = AppGroup.defaults) -> Bool {
        guard let defaults else { return false }
        let previous = load(from: defaults)
        guard let snapshot else {
            defaults.removeObject(forKey: key)
            return previous != nil
        }
        // generatedAt her yazımda değişir; karşılaştırmayı onsuz yap.
        var comparable = snapshot
        comparable.generatedAt = previous?.generatedAt ?? snapshot.generatedAt
        if comparable == previous { return false }
        guard let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}
