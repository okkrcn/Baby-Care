import Foundation
import SwiftData

@Model
final class GrowthRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var recordedAt: Date
    var weightGrams: Int?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        babyID: UUID,
        recordedAt: Date = .now,
        weightGrams: Int? = nil,
        heightCm: Double? = nil,
        headCircumferenceCm: Double? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.recordedAt = recordedAt
        self.weightGrams = weightGrams
        self.heightCm = heightCm
        self.headCircumferenceCm = headCircumferenceCm
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
