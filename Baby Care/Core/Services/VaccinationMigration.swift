import Foundation
import SwiftData

/// Takvimden çıkarılan aşı tanımları için tek seferlik veri temizliği.
///
/// 2025 ulusal takviminde KPA şeması 2+1 olduğu için `kpa_6m` emekliye
/// ayrıldı. Mevcut kullanıcılarda o tanıma bağlı planlanmış kayıtlar
/// kalabilir; yapılmamış olanlar silinir. Tamamlanmış kayıtlara
/// dokunulmaz — kullanıcı gerçekten yaptırmış olabilir.
@MainActor
enum VaccinationMigration {

    @discardableResult
    static func removeRetiredPendingRecords(in context: ModelContext) async -> Int {
        let retiredIDs = Set(VaccineCatalog.schedule.filter(\.isRetired).map(\.id))
        guard !retiredIDs.isEmpty else { return 0 }

        let all = (try? context.fetch(FetchDescriptor<VaccinationRecord>())) ?? []
        let targets = all.filter {
            retiredIDs.contains($0.vaccineDefinitionID) && $0.completedDate == nil
        }
        guard !targets.isEmpty else { return 0 }

        for record in targets {
            await NotificationService.cancelReminders(for: record)
            context.delete(record)
        }
        try? context.save()
        return targets.count
    }
}
