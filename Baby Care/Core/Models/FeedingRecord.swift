import Foundation
import SwiftData

enum FeedingType: String, Codable, CaseIterable, Sendable {
    case breast            // anne memesi
    case bottleBreastmilk  // biberon — sağılmış süt
    case bottleFormula     // biberon — mama

    var localizedTitle: String {
        switch self {
        case .breast:           return "Anne sütü (emzirme)"
        case .bottleBreastmilk: return "Sağılmış süt (biberon)"
        case .bottleFormula:    return "Mama (biberon)"
        }
    }

    var icon: String {
        switch self {
        case .breast:           return "drop.fill"
        case .bottleBreastmilk: return "drop.degreesign.fill"
        case .bottleFormula:    return "takeoutbag.and.cup.and.straw.fill"
        }
    }

    var isBottle: Bool {
        self == .bottleBreastmilk || self == .bottleFormula
    }
}

enum BreastSide: String, Codable, CaseIterable, Sendable {
    case left
    case right
    case both

    var localizedTitle: String {
        switch self {
        case .left:  return "Sol"
        case .right: return "Sağ"
        case .both:  return "İkisi"
        }
    }
}

@Model
final class FeedingRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var typeRaw: String
    var startedAt: Date
    var endedAt: Date?            // canlı emzirme: nil = devam ediyor
    var durationSeconds: Int?
    var sideRaw: String?
    var amountML: Int?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var type: FeedingType {
        get { FeedingType(rawValue: typeRaw) ?? .breast }
        set { typeRaw = newValue.rawValue }
    }

    var side: BreastSide? {
        get { sideRaw.flatMap(BreastSide.init(rawValue:)) }
        set { sideRaw = newValue?.rawValue }
    }

    /// Canlı emzirme kaydı mı (başlatılmış, henüz bitirilmemiş)
    var isOngoing: Bool {
        endedAt == nil && durationSeconds == nil && type == .breast
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        type: FeedingType,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        side: BreastSide? = nil,
        amountML: Int? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.typeRaw = type.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.sideRaw = side?.rawValue
        self.amountML = amountML
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
