import Foundation
import SwiftData

@Model
final class SleepRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var startedAt: Date
    var endedAt: Date?
    var isNap: Bool             // true = gündüz şekerleme, false = gece uykusu
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    /// Devam eden kayıt mı? (endedAt henüz set edilmemiş)
    var isOngoing: Bool { endedAt == nil }

    /// Süre saniye cinsinden. Devam ediyorsa şu ana kadar olan süre.
    var durationSeconds: Int {
        let end = endedAt ?? .now
        return max(0, Int(end.timeIntervalSince(startedAt)))
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        isNap: Bool = true,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isNap = isNap
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
