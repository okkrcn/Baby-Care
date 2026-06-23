import Foundation
import SwiftData

/// Sağılmış anne sütü saklama yeri.
/// Süreler CDC ve WHO anne sütü saklama kılavuzlarına göre (ideal değerler).
enum MilkStorageLocation: String, Codable, CaseIterable, Sendable {
    case room      // Oda sıcaklığı (<25°C)
    case fridge    // Buzdolabı (≤4°C)
    case freezer   // Derin dondurucu (≤-18°C)

    var localizedTitle: String {
        switch self {
        case .room:    return "Oda Sıcaklığı"
        case .fridge:  return "Buzdolabı"
        case .freezer: return "Derin Dondurucu"
        }
    }

    var subtitle: String {
        switch self {
        case .room:    return "<25°C — 4 saat"
        case .fridge:  return "≤4°C — 4 gün"
        case .freezer: return "≤-18°C — 6 ay"
        }
    }

    var icon: String {
        switch self {
        case .room:    return "thermometer.sun.fill"
        case .fridge:  return "refrigerator.fill"
        case .freezer: return "snowflake"
        }
    }

    /// Güvenli saklama süresi (saat).
    var maxHours: Int {
        switch self {
        case .room:    return 4
        case .fridge:  return 96       // 4 gün × 24 saat
        case .freezer: return 4320     // 6 ay × 30 gün × 24 saat (yaklaşık)
        }
    }
}

@Model
final class BreastMilkBatch {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var pumpedAt: Date
    var amountML: Int
    var storageRaw: String
    var expiresAt: Date
    var usedAt: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var storage: MilkStorageLocation {
        get { MilkStorageLocation(rawValue: storageRaw) ?? .fridge }
        set { storageRaw = newValue.rawValue }
    }

    var isUsed: Bool { usedAt != nil }

    var isExpired: Bool {
        !isUsed && expiresAt < .now
    }

    var isActive: Bool {
        !isUsed && !isExpired
    }

    /// Bitişine ne kadar saat kaldı (negatifse dolmuş).
    var hoursUntilExpiry: Double {
        expiresAt.timeIntervalSince(.now) / 3600.0
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        pumpedAt: Date = .now,
        amountML: Int,
        storage: MilkStorageLocation,
        expiresAt: Date? = nil,
        usedAt: Date? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.pumpedAt = pumpedAt
        self.amountML = amountML
        self.storageRaw = storage.rawValue
        // Bitiş tarihi otomatik hesaplanır
        self.expiresAt = expiresAt ?? pumpedAt.addingTimeInterval(TimeInterval(storage.maxHours * 3600))
        self.usedAt = usedAt
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
