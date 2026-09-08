import SwiftUI
import SwiftData

/// Üst düzey kapı:
///  - Henüz bebek eklenmemişse → OnboardingView
///  - En az bir bebek varsa → RootTabView
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var babies: [Baby]

    var body: some View {
        Group {
            if babies.isEmpty {
                OnboardingView()
            } else {
                RootTabView()
            }
        }
        .task {
            // Takvimden çıkarılmış aşı kayıtlarını temizle (idempotent)
            await VaccinationMigration.removeRetiredPendingRecords(in: modelContext)
            // Pazar 19:00 haftalık özet + Pazar 10:00 büyüme ölçüm hatırlatması
            await NotificationService.scheduleWeeklySummary()
            await NotificationService.scheduleWeeklyGrowthReminder()
        }
    }
}
