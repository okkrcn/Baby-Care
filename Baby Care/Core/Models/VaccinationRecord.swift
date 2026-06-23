import Foundation
import SwiftData

@Model
final class VaccinationRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var vaccineDefinitionID: String     // VaccineCatalog id'sine referans
    var scheduledDate: Date              // doğum tarihinden hesaplanmış planlanmış tarih
    var completedDate: Date?             // gerçekten yapıldığı tarih
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var isCompleted: Bool { completedDate != nil }

    var definition: VaccineDefinition? {
        VaccineCatalog.definition(forID: vaccineDefinitionID)
    }

    /// Bugünden kaç gün uzakta (negatif = geçmiş)
    var daysFromToday: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                        to: Calendar.current.startOfDay(for: scheduledDate)).day ?? 0
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        vaccineDefinitionID: String,
        scheduledDate: Date,
        completedDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.vaccineDefinitionID = vaccineDefinitionID
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
