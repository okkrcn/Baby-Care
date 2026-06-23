import SwiftUI
import SwiftData

struct FeedingCalculatorView: View {
    let baby: Baby

    @Query(sort: \GrowthRecord.recordedAt, order: .reverse) private var allGrowth: [GrowthRecord]
    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]

    /// Kullanıcının manuel değiştirebileceği kilo (kg).
    @State private var weightKg: Double = 3.5
    @State private var didInitialize = false

    private var ageDays: Int { baby.ageInDays }

    private var result: FeedingCalculator.Result {
        FeedingCalculator.calculate(ageDays: ageDays, weightKg: weightKg)
    }

    private var todayBottleML: Int {
        allFeedings
            .filter { $0.babyID == baby.id && Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + ($1.amountML ?? 0) }
    }

    var body: some View {
        List {
            Section("Bebeğin Mevcut Kilosu") {
                HStack {
                    Text(String(format: "%.2f kg", weightKg))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.pink)
                    Spacer()
                    Stepper("Kilo", value: $weightKg, in: 1.0...15.0, step: 0.05)
                        .labelsHidden()
                }
                if let latest = latestGrowthWeight {
                    Text("Son ölçüm: \(latest.0) g — \(DateFormatters.displayDate.string(from: latest.1))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let birth = baby.birthWeightGrams {
                    Text("Doğum kilosu varsayıldı: \(birth) g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                summaryRow
            } header: {
                Text("Önerilen Günlük Toplam")
            } footer: {
                Text("\(Int(result.mlPerKgMin))–\(Int(result.mlPerKgMax)) ml/kg/gün formülüne göre.")
            }

            Section("Öğün Başına") {
                ForEach([5, 6, 7, 8, 10], id: \.self) { n in
                    HStack {
                        Image(systemName: feedingsIcon(n))
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text("\(n) öğün")
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        Text("≈ \(result.mlPerMeal(forFeedings: n)) ml")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.primary)
                        if n == result.typicalFeedingsPerDay {
                            Text("Önerilen")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.pink.opacity(0.15), in: .capsule)
                                .foregroundStyle(.pink)
                        }
                    }
                }
            }

            Section("Bugün") {
                progressRow
                Text("Yalnızca biberon (ml girilen) öğünler sayılır; emzirme süreleri burada yer almaz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Kalori (yaklaşık)") {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(result.dailyCaloriesMin)–\(result.dailyCaloriesMax) kcal/gün")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                Text("Anne sütü ve standart mama ≈ 67 kcal / 100 ml")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Yaşa Göre Tipik Öğün Sayısı") {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.indigo)
                    Text(typicalFeedingsLabel)
                }
                .font(.subheadline)
            }

            Section {
                Text("Bu değerler referanstır. Bebeğiniz doyana kadar emzirilmeli/biberonla beslenmelidir; sayısal hedefleri zorlamak yerine bebeğin işaretlerini (tokluk, kilo alımı, idrar sayısı) takip edin. Tıbbi kararlar için pediatristinize danışın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Beslenme Hesabı")
        .onAppear { initializeWeightIfNeeded() }
    }

    // MARK: - Subviews

    private var summaryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(result.dailyAverageML) ml")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.pink)
                Text("/ gün")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            HStack {
                Label("Min: \(result.dailyMinML) ml", systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("Maks: \(result.dailyMaxML) ml", systemImage: "arrow.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var progressRow: some View {
        let target = max(result.dailyAverageML, 1)
        let progress = min(Double(todayBottleML) / Double(target), 1.5)
        let percentage = Int(progress * 100)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(todayBottleML) ml")
                    .font(.title3.weight(.semibold))
                Text("/ \(result.dailyAverageML) ml")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(percentage)%")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(progressColor(progress))
            }
            ProgressView(value: min(progress, 1.0))
                .tint(progressColor(progress))
        }
    }

    // MARK: - Helpers

    private func progressColor(_ p: Double) -> Color {
        switch p {
        case ..<0.5:  return .orange
        case 0.5..<0.9: return .yellow
        case 0.9...1.1: return .green
        default: return .blue
        }
    }

    private var typicalFeedingsLabel: String {
        switch ageDays {
        case 0..<30:   return "0–1 ay: günde 8–12 öğün tipiktir"
        case 30..<90:  return "1–3 ay: günde 6–8 öğün tipiktir"
        case 90..<180: return "3–6 ay: günde 4–6 öğün tipiktir"
        default:       return "6+ ay: günde 4–5 öğün tipiktir"
        }
    }

    private func feedingsIcon(_ n: Int) -> String {
        switch n {
        case ...5:  return "5.circle.fill"
        case 6:     return "6.circle.fill"
        case 7:     return "7.circle.fill"
        case 8:     return "8.circle.fill"
        default:    return "circle.grid.2x2.fill"
        }
    }

    private var latestGrowthWeight: (Int, Date)? {
        if let rec = allGrowth.first(where: { $0.babyID == baby.id && $0.weightGrams != nil }),
           let w = rec.weightGrams {
            return (w, rec.recordedAt)
        }
        return nil
    }

    private func initializeWeightIfNeeded() {
        guard !didInitialize else { return }
        didInitialize = true

        if let (grams, _) = latestGrowthWeight {
            weightKg = Double(grams) / 1000.0
        } else if let birth = baby.birthWeightGrams {
            weightKg = Double(birth) / 1000.0
        } else {
            // Yaşa göre ortalama tahmin
            let estimated: Double
            switch baby.ageInMonths {
            case 0:  estimated = 3.5
            case 1:  estimated = 4.2
            case 2:  estimated = 5.1
            case 3:  estimated = 5.8
            case 4:  estimated = 6.4
            case 5:  estimated = 6.9
            default: estimated = 7.3
            }
            weightKg = estimated
        }
    }
}
