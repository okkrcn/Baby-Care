import Foundation
import SwiftData

/// Bir bebeği ve ona ait TÜM ilgili kayıtları + bildirimleri siler.
/// Cascade delete pattern — SwiftData @Relationship kullanmadığımız için manuel.
@MainActor
enum BabyDeleteService {
    static func delete(_ baby: Baby, from context: ModelContext) async {
        let babyID = baby.id

        // İlişkili kayıtları topla ve sil
        deleteAll(FeedingRecord.self, babyID: babyID, in: context)
        deleteAll(SleepRecord.self,   babyID: babyID, in: context)
        deleteAll(DiaperRecord.self,  babyID: babyID, in: context)
        deleteAll(GrowthRecord.self,  babyID: babyID, in: context)
        deleteAll(BreastMilkBatch.self, babyID: babyID, in: context)
        deleteAll(SolidFoodRecord.self, babyID: babyID, in: context)
        deleteAll(AllergenIntroduction.self, babyID: babyID, in: context)

        // Aşı kayıtlarını sil + bildirimleri iptal et
        let vaccPredicate = #Predicate<VaccinationRecord> { $0.babyID == babyID }
        let vaccs = (try? context.fetch(FetchDescriptor<VaccinationRecord>(predicate: vaccPredicate))) ?? []
        for v in vaccs {
            await NotificationService.cancelReminders(for: v)
            context.delete(v)
        }

        // İlaçları sil + bildirimleri + doz kayıtlarını iptal et
        let medPredicate = #Predicate<Medication> { $0.babyID == babyID }
        let meds = (try? context.fetch(FetchDescriptor<Medication>(predicate: medPredicate))) ?? []
        let medIDs = Set(meds.map { $0.id })
        for m in meds {
            await NotificationService.cancelReminders(for: m)
            context.delete(m)
        }
        // İlaç dozları (Medication doses)
        let doses = (try? context.fetch(FetchDescriptor<MedicationDose>())) ?? []
        for d in doses where medIDs.contains(d.medicationID) {
            context.delete(d)
        }

        // Bebeği sil
        context.delete(baby)
        try? context.save()
    }

    private static func deleteAll<T: PersistentModel>(
        _ type: T.Type,
        babyID: UUID,
        in context: ModelContext
    ) where T: HasBabyID {
        let predicate = #Predicate<T> { $0.babyID == babyID }
        let items = (try? context.fetch(FetchDescriptor<T>(predicate: predicate))) ?? []
        for item in items { context.delete(item) }
    }
}

/// Sadece bu service için generic protokol — `babyID` property'sine sahip modelleri işaret eder.
protocol HasBabyID {
    var babyID: UUID { get }
}

extension FeedingRecord:   HasBabyID {}
extension SleepRecord:     HasBabyID {}
extension DiaperRecord:    HasBabyID {}
extension GrowthRecord:    HasBabyID {}
extension BreastMilkBatch: HasBabyID {}
extension SolidFoodRecord:      HasBabyID {}
extension AllergenIntroduction: HasBabyID {}
