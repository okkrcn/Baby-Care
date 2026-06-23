import Foundation
import SwiftData

enum DiaperType: String, Codable, CaseIterable, Sendable {
    case pee
    case poo
    case both

    var localizedTitle: String {
        switch self {
        case .pee:  return "Çiş"
        case .poo:  return "Kaka"
        case .both: return "Karışık"
        }
    }

    var icon: String {
        switch self {
        case .pee:  return "drop.fill"
        case .poo:  return "circle.hexagongrid.fill"
        case .both: return "leaf.fill"
        }
    }

    var color: String {
        switch self {
        case .pee:  return "yellow"
        case .poo:  return "brown"
        case .both: return "green"
        }
    }
}

enum PooConsistency: String, Codable, CaseIterable, Sendable {
    case soft
    case normal
    case loose
    case hard

    var localizedTitle: String {
        switch self {
        case .soft:   return "Yumuşak"
        case .normal: return "Normal"
        case .loose:  return "Sulu / İshal"
        case .hard:   return "Sert / Kabız"
        }
    }
}

@Model
final class DiaperRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var recordedAt: Date
    var typeRaw: String
    var consistencyRaw: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var type: DiaperType {
        get { DiaperType(rawValue: typeRaw) ?? .pee }
        set { typeRaw = newValue.rawValue }
    }

    var consistency: PooConsistency? {
        get { consistencyRaw.flatMap(PooConsistency.init(rawValue:)) }
        set { consistencyRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        recordedAt: Date = .now,
        type: DiaperType,
        consistency: PooConsistency? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.recordedAt = recordedAt
        self.typeRaw = type.rawValue
        self.consistencyRaw = consistency?.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
