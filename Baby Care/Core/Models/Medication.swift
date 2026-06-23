import Foundation
import SwiftData

@Model
final class Medication {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var name: String                  // "D Vitamini", "Demir Damlası" vs.
    var dosageText: String            // "3 damla (400 IU)" gibi serbest metin
    var icon: String                  // SF Symbol
    var startedAt: Date
    var endedAt: Date?
    var reminderHour: Int             // 0-23, varsayılan günlük hatırlatma saati
    var reminderMinute: Int
    var isActive: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        babyID: UUID,
        name: String,
        dosageText: String,
        icon: String = "pills.fill",
        startedAt: Date = .now,
        endedAt: Date? = nil,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        isActive: Bool = true,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.name = name
        self.dosageText = dosageText
        self.icon = icon
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isActive = isActive
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class MedicationDose {
    @Attribute(.unique) var id: UUID
    var medicationID: UUID
    var takenAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        medicationID: UUID,
        takenAt: Date = .now,
        notes: String? = nil
    ) {
        self.id = id
        self.medicationID = medicationID
        self.takenAt = takenAt
        self.notes = notes
    }
}

extension Medication {
    /// T.C. Sağlık Bakanlığı önerisi: 0-12 ay arası tüm bebeklere günlük 400 IU D vitamini.
    /// Yeni bebek oluştuğunda otomatik eklenir.
    static func defaultVitaminD(for babyID: UUID, startedAt: Date) -> Medication {
        Medication(
            babyID: babyID,
            name: "D Vitamini",
            dosageText: "Günde 3 damla (400 IU)",
            icon: "sun.max.fill",
            startedAt: startedAt,
            reminderHour: 10,
            reminderMinute: 0,
            notes: "T.C. Sağlık Bakanlığı 0-12 ay tüm bebeklere günlük 400 IU D vitamini önerir."
        )
    }
}
