import Foundation
import SwiftData

/// Yeni bir bebek oluşturulduğunda yapılması gereken işleri tek noktada toplar:
/// aşı takvimi üretimi + D vitamini default'u + bildirim planlama.
@MainActor
enum BabyOnboardingService {
    static func setupNewBaby(_ baby: Baby, in context: ModelContext) {
        VaccinationScheduler.generateSchedule(for: baby, in: context)

        let medication = Medication.defaultVitaminD(for: baby.id, startedAt: baby.birthDate)
        context.insert(medication)
        try? context.save()

        let babyName = baby.name
        Task {
            await NotificationService.scheduleDailyReminder(for: medication, babyName: babyName)
        }
    }
}
