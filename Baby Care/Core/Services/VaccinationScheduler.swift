import Foundation
import SwiftData

@MainActor
enum VaccinationScheduler {
    /// Yeni bir bebek için aşı takvimini üretip ekler.
    /// Daha önce aynı bebek + aynı aşı için kayıt varsa atlanır.
    static func generateSchedule(for baby: Baby, in context: ModelContext) {
        let babyID = baby.id
        let descriptor = FetchDescriptor<VaccinationRecord>(
            predicate: #Predicate { $0.babyID == babyID }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingIDs = Set(existing.map { $0.vaccineDefinitionID })

        let calendar = Calendar.current

        for vaccine in VaccineCatalog.firstSixMonths {
            if existingIDs.contains(vaccine.id) { continue }

            var components = DateComponents()
            components.month = vaccine.scheduledAgeMonths
            components.day = vaccine.scheduledAgeDays

            guard let scheduledDate = calendar.date(byAdding: components, to: baby.birthDate) else {
                continue
            }

            // Doğum dozu (0. ay, 0. gün) için doğum tarihini "yapıldı" olarak işaretleme.
            // Doktor doğumda zaten yaptıysa kullanıcı manuel onaylayabilir.
            let record = VaccinationRecord(
                babyID: baby.id,
                vaccineDefinitionID: vaccine.id,
                scheduledDate: scheduledDate
            )
            context.insert(record)
        }

        try? context.save()
    }
}
