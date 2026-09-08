import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    let baby: Baby

    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]
    @Query(sort: \SleepRecord.startedAt, order: .reverse) private var allSleeps: [SleepRecord]
    @Query(sort: \DiaperRecord.recordedAt, order: .reverse) private var allDiapers: [DiaperRecord]
    @Query(sort: \GrowthRecord.recordedAt) private var allGrowth: [GrowthRecord]
    @Query(sort: \VaccinationRecord.scheduledDate) private var allVaccinations: [VaccinationRecord]
    @Query(sort: \SolidFoodRecord.servedAt, order: .reverse) private var allSolids: [SolidFoodRecord]

    private var summary: WeeklySummary {
        WeeklySummaryCalculator.calculate(
            for: baby,
            feedings: allFeedings,
            sleeps: allSleeps,
            diapers: allDiapers,
            growth: allGrowth,
            vaccinations: allVaccinations,
            solidFoods: allSolids
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                statSection(title: "Beslenme", color: .blue, icon: "drop.fill") {
                    statRow("Toplam öğün", "\(summary.totalFeedings)")
                    statRow("Günlük ortalama", String(format: "%.1f öğün", summary.averageFeedingsPerDay))
                    if summary.totalBreastfeedingSeconds > 0 {
                        statRow("Emzirme süresi", DurationFormatter.string(fromSeconds: summary.totalBreastfeedingSeconds))
                    }
                    if summary.totalBottleML > 0 {
                        statRow("Biberon toplam", "\(summary.totalBottleML) ml")
                    }
                }

                if baby.stage.isSolidFoodAge {
                    statSection(title: "Ek Gıda", color: .brown, icon: "carrot.fill") {
                        statRow("Toplam öğün", "\(summary.solidFoodMeals)")
                        statRow("Yeni denenen besin", "\(summary.newFoodsTried)")
                    }
                }

                statSection(title: "Uyku", color: .indigo, icon: "moon.zzz.fill") {
                    statRow("Toplam uyku", DurationFormatter.string(fromSeconds: summary.totalSleepSeconds))
                    statRow("Günlük ortalama", String(format: "%.1f saat", summary.averageSleepHoursPerDay))
                    statRow("Gece uykusu", "\(summary.nightSleepCount) kez")
                    statRow("Gündüz şekerleme", "\(summary.napCount) kez")
                }

                statSection(title: "Bez", color: .green, icon: "leaf.fill") {
                    statRow("Toplam değişim", "\(summary.totalDiapers)")
                    statRow("Günlük ortalama", String(format: "%.1f değişim", summary.averageDiapersPerDay))
                }

                if summary.weightChangeGrams != nil || summary.heightChangeCm != nil {
                    statSection(title: "Büyüme", color: .pink, icon: "chart.line.uptrend.xyaxis") {
                        if let w = summary.weightChangeGrams {
                            statRow("Kilo değişimi", "\(w > 0 ? "+" : "")\(w) g")
                        }
                        if let h = summary.heightChangeCm {
                            statRow("Boy değişimi", String(format: "%@%.1f cm", h > 0 ? "+" : "", h))
                        }
                    }
                }

                if summary.completedVaccinations > 0 {
                    statSection(title: "Aşı", color: .red, icon: "syringe.fill") {
                        statRow("Tamamlanan", "\(summary.completedVaccinations)")
                    }
                }

                Text("Bu özet son 7 günü kapsar. Veriler eklediğiniz kayıtlardan otomatik çıkarılır; eksik kayıt varsa rakamlar eksik gözükebilir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Haftalık Özet")
        .inlineNavigationTitle()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(baby.name) — Bu Hafta")
                .font(.title2.bold())
            Text("\(DateFormatters.displayDate.string(from: summary.weekStart)) – \(DateFormatters.displayDate.string(from: summary.weekEnd))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func statSection(title: String, color: Color, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }
            VStack(spacing: 6) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.06), in: .rect(cornerRadius: 14))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}
