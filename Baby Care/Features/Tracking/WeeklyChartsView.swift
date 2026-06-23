import SwiftUI
import SwiftData
import Charts

/// Takip için grafik/istatistik sayfası.
/// - Son 7 gün: beslenme öğün sayısı, bez değişim sayısı, uyku saati (bar grafikleri)
/// - Tüm zaman: kilo (kg) ve boy (cm) ölçümleri (animasyonlu çizgi grafikleri)
struct WeeklyChartsView: View {
    let baby: Baby

    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]
    @Query(sort: \SleepRecord.startedAt, order: .reverse) private var allSleeps: [SleepRecord]
    @Query(sort: \DiaperRecord.recordedAt, order: .reverse) private var allDiapers: [DiaperRecord]
    @Query(sort: \GrowthRecord.recordedAt) private var allGrowth: [GrowthRecord]

    @State private var animate = false

    // MARK: - Gün penceresi

    private struct DayValue: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let value: Double
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "EEE"
        return f
    }()

    /// Son 7 gün (en eski → bugün)
    private var last7Days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    private func feedingsPerDay() -> [DayValue] {
        let cal = Calendar.current
        let mine = allFeedings.filter { $0.babyID == baby.id }
        return last7Days.map { day in
            let count = mine.filter { cal.isDate($0.startedAt, inSameDayAs: day) }.count
            return DayValue(date: day, label: Self.weekdayFormatter.string(from: day), value: Double(count))
        }
    }

    private func diapersPerDay() -> [DayValue] {
        let cal = Calendar.current
        let mine = allDiapers.filter { $0.babyID == baby.id }
        return last7Days.map { day in
            let count = mine.filter { cal.isDate($0.recordedAt, inSameDayAs: day) }.count
            return DayValue(date: day, label: Self.weekdayFormatter.string(from: day), value: Double(count))
        }
    }

    private func sleepHoursPerDay() -> [DayValue] {
        let cal = Calendar.current
        let mine = allSleeps.filter { $0.babyID == baby.id }
        return last7Days.map { day in
            let seconds = mine
                .filter { cal.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationSeconds }
            return DayValue(date: day, label: Self.weekdayFormatter.string(from: day), value: Double(seconds) / 3600.0)
        }
    }

    private struct MeasurePoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private var weightPoints: [MeasurePoint] {
        allGrowth
            .filter { $0.babyID == baby.id }
            .compactMap { rec in
                guard let g = rec.weightGrams else { return nil }
                return MeasurePoint(date: rec.recordedAt, value: Double(g) / 1000.0)
            }
    }

    private var heightPoints: [MeasurePoint] {
        allGrowth
            .filter { $0.babyID == baby.id }
            .compactMap { rec in
                guard let h = rec.heightCm else { return nil }
                return MeasurePoint(date: rec.recordedAt, value: h)
            }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                barCard(
                    title: "Beslenme",
                    subtitle: "Son 7 gün · günlük öğün sayısı",
                    icon: "drop.fill",
                    color: .blue,
                    data: feedingsPerDay(),
                    unit: "öğün"
                )

                barCard(
                    title: "Bez Değişimi",
                    subtitle: "Son 7 gün · günlük adet",
                    icon: "leaf.fill",
                    color: .green,
                    data: diapersPerDay(),
                    unit: "adet"
                )

                barCard(
                    title: "Uyku",
                    subtitle: "Son 7 gün · günlük toplam saat",
                    icon: "moon.zzz.fill",
                    color: .indigo,
                    data: sleepHoursPerDay(),
                    unit: "saat"
                )

                measureCard(
                    title: "Kilo",
                    subtitle: "Ölçüm geçmişi",
                    icon: "scalemass.fill",
                    color: .pink,
                    data: weightPoints,
                    unit: "kg"
                )

                measureCard(
                    title: "Boy",
                    subtitle: "Ölçüm geçmişi",
                    icon: "ruler.fill",
                    color: .orange,
                    data: heightPoints,
                    unit: "cm"
                )
            }
            .padding()
        }
        .navigationTitle("Grafikler")
        .inlineNavigationTitle()
        .onAppear { animate = true }
    }

    // MARK: - Bar card (haftalık)

    private func barCard(title: String, subtitle: String, icon: String, color: Color, data: [DayValue], unit: String) -> some View {
        let total = data.reduce(0) { $0 + $1.value }
        return VStack(alignment: .leading, spacing: 8) {
            cardHeader(title: title, subtitle: subtitle, icon: icon, color: color)

            if total == 0 {
                emptyHint
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Gün", item.label),
                        y: .value(unit, animate ? item.value : 0)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(6)
                }
                .chartYAxisLabel(unit)
                .frame(height: 180)
                .animation(.easeOut(duration: 0.6), value: animate)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    // MARK: - Measure card (boy/kilo)

    private func measureCard(title: String, subtitle: String, icon: String, color: Color, data: [MeasurePoint], unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader(title: title, subtitle: subtitle, icon: icon, color: color)

            if data.isEmpty {
                emptyHint
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value(unit, point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Tarih", point.date),
                        y: .value(unit, point.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(animate ? 60 : 0)
                    .opacity(animate ? 1 : 0)
                }
                .chartYAxisLabel(unit)
                .frame(height: 180)
                .animation(.easeOut(duration: 0.6), value: animate)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    // MARK: - Shared

    private func cardHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: .circle)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var emptyHint: some View {
        Text("Henüz veri yok.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 24)
    }
}
