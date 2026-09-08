import Foundation
import SwiftData

enum AllergenStatus: String, Codable, CaseIterable, Sendable {
    case notIntroduced
    case introduced   // verildi, henüz tekrarlanmadı
    case tolerated    // sorunsuz tekrarlandı
    case reacted      // olumsuz tepki gözlendi

    var localizedTitle: String {
        switch self {
        case .notIntroduced: return "Henüz verilmedi"
        case .introduced:    return "Tanıtıldı"
        case .tolerated:     return "Sorunsuz"
        case .reacted:       return "Tepki gözlendi"
        }
    }

    var icon: String {
        switch self {
        case .notIntroduced: return "circle.dashed"
        case .introduced:    return "circle.lefthalf.filled"
        case .tolerated:     return "checkmark.circle.fill"
        case .reacted:       return "exclamationmark.triangle.fill"
        }
    }
}

/// Bir bebeğin tek bir major alerjenle ilişkisi.
///
/// `lastServedAt` alanı AAP 2023 önerisi içindir: tolere edilen alerjen
/// diyette düzenli tutulmalıdır, tek tadım koruyucu etki için yeterli
/// değildir.
@Model
final class AllergenIntroduction {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var allergenRaw: String
    var statusRaw: String
    var firstTriedAt: Date?
    var lastServedAt: Date?
    var reactionNotes: String?
    var createdAt: Date
    var updatedAt: Date

    /// Tolere edilen bir alerjen bu kadar gün verilmezse hatırlatılır.
    static let regularityThresholdDays = 14

    var allergen: Allergen {
        get { Allergen(rawValue: allergenRaw) ?? .milk }
        set { allergenRaw = newValue.rawValue }
    }

    var status: AllergenStatus {
        get { AllergenStatus(rawValue: statusRaw) ?? .notIntroduced }
        set { statusRaw = newValue.rawValue }
    }

    var daysSinceLastServed: Int? {
        guard let last = lastServedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: .now).day
    }

    /// Tolere edilmiş ama uzun süredir verilmemiş alerjen için hatırlatma.
    /// Tepki gözlenmiş alerjende asla true dönmez — o besin hekim
    /// değerlendirmesi olmadan evde tekrar denenmez.
    var needsRegularityReminder: Bool {
        guard status == .tolerated, let days = daysSinceLastServed else { return false }
        return days >= Self.regularityThresholdDays
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        allergen: Allergen,
        status: AllergenStatus = .notIntroduced,
        firstTriedAt: Date? = nil,
        lastServedAt: Date? = nil,
        reactionNotes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.allergenRaw = allergen.rawValue
        self.statusRaw = status.rawValue
        self.firstTriedAt = firstTriedAt
        self.lastServedAt = lastServedAt
        self.reactionNotes = reactionNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
