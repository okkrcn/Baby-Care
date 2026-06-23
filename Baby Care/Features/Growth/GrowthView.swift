import SwiftUI
import SwiftData
import Charts

struct GrowthView: View {
    let baby: Baby

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GrowthRecord.recordedAt) private var allGrowth: [GrowthRecord]

    @State private var selectedMetric: WHOPercentiles.Metric = .weight
    @State private var showAddSheet = false
    @State private var editingRecord: GrowthRecord?

    private var records: [GrowthRecord] {
        allGrowth.filter { $0.babyID == baby.id }
    }

    private var sex: WHOPercentiles.Sex {
        WHOPercentiles.Sex(from: baby.sex)
    }

    var body: some View {
        List {
            Section {
                Picker("Ölçüm", selection: $selectedMetric) {
                    Text("Kilo").tag(WHOPercentiles.Metric.weight)
                    Text("Boy").tag(WHOPercentiles.Metric.height)
                    Text("Baş Çevresi").tag(WHOPercentiles.Metric.head)
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))

            Section {
                chartView
                    .frame(height: 240)
                    .padding(.vertical, 4)
            } header: {
                Text("DSÖ Persentil Grafiği — \(sexLabel)")
            }

            if let latest = latestRecordWithValue(for: selectedMetric) {
                Section("Son Değer") {
                    latestValueRow(record: latest)
                }
            }

            Section("Geçmiş Ölçümler") {
                if records.isEmpty {
                    Text("Henüz ölçüm eklenmemiş.")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                } else {
                    ForEach(records.reversed()) { rec in
                        Button {
                            editingRecord = rec
                        } label: {
                            historyRow(rec)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            }

            Section {
                Text("Persentil bantları DSÖ Çocuk Büyüme Standartları'na dayanır. Bilgilendirme amaçlıdır, hekim değerlendirmesinin yerini tutmaz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Büyüme")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            GrowthAddSheet(babyID: baby.id)
        }
        .sheet(item: $editingRecord) { rec in
            GrowthAddSheet(babyID: baby.id, editing: rec)
        }
    }

    private var sexLabel: String {
        switch baby.sex {
        case .female: return "Kız"
        case .male:   return "Erkek"
        case .unspecified: return "Erkek (varsayılan)"
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartView: some View {
        let rows = WHOPercentiles.data(for: selectedMetric, sex: sex)
        let unit = selectedMetric.unitLabel

        Chart {
            // Persentil bantları
            ForEach(rows, id: \.month) { row in
                AreaMark(
                    x: .value("Ay", row.month),
                    yStart: .value("Alt", row.p15),
                    yEnd:   .value("Üst", row.p85)
                )
                .foregroundStyle(.green.opacity(0.18))
            }
            ForEach(rows, id: \.month) { row in
                LineMark(x: .value("Ay", row.month), y: .value("P50", row.p50))
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
            }
            ForEach(rows, id: \.month) { row in
                LineMark(x: .value("Ay", row.month), y: .value("P3", row.p3))
                    .foregroundStyle(.gray)
                    .lineStyle(.init(lineWidth: 1, dash: [3, 3]))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(rows, id: \.month) { row in
                LineMark(x: .value("Ay", row.month), y: .value("P97", row.p97))
                    .foregroundStyle(.gray)
                    .lineStyle(.init(lineWidth: 1, dash: [3, 3]))
                    .interpolationMethod(.catmullRom)
            }

            // Bebeğin ölçüm noktaları
            ForEach(records) { rec in
                if let value = displayValue(for: rec, metric: selectedMetric) {
                    PointMark(
                        x: .value("Ay", ageMonths(at: rec.recordedAt)),
                        y: .value(selectedMetric.title, value)
                    )
                    .foregroundStyle(.pink)
                    .symbolSize(80)
                }
            }
        }
        .chartXAxisLabel("Ay")
        .chartYAxisLabel(unit)
        .chartXScale(domain: 0...6)
    }

    private func ageMonths(at date: Date) -> Double {
        let components = Calendar.current.dateComponents([.day], from: baby.birthDate, to: date)
        let days = Double(components.day ?? 0)
        return max(0, days / 30.4375)
    }

    private func displayValue(for rec: GrowthRecord, metric: WHOPercentiles.Metric) -> Double? {
        switch metric {
        case .weight:
            guard let g = rec.weightGrams else { return nil }
            return Double(g) / 1000.0
        case .height:
            return rec.heightCm
        case .head:
            return rec.headCircumferenceCm
        }
    }

    // MARK: - Latest value

    private func latestRecordWithValue(for metric: WHOPercentiles.Metric) -> GrowthRecord? {
        records.reversed().first { displayValue(for: $0, metric: metric) != nil }
    }

    private func latestValueRow(record rec: GrowthRecord) -> some View {
        let value = displayValue(for: rec, metric: selectedMetric) ?? 0
        let months = Int(round(ageMonths(at: rec.recordedAt)))
        let band = WHOPercentiles.percentileBand(
            metric: selectedMetric, sex: sex, ageMonths: months, value: value
        )

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(selectedMetric.title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f %@", value, selectedMetric.unitLabel))
                    .font(.subheadline.bold())
            }
            HStack {
                Text(DateFormatters.displayDate.string(from: rec.recordedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(band)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(bandColor(band))
            }
        }
    }

    private func bandColor(_ band: String) -> Color {
        if band.contains("normal") { return .green }
        if band.contains("< 3") || band.contains("> 97") { return .red }
        return .orange
    }

    // MARK: - History

    private func historyRow(_ rec: GrowthRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DateFormatters.displayDate.string(from: rec.recordedAt))
                .font(.subheadline.weight(.medium))
            HStack(spacing: 12) {
                if let g = rec.weightGrams {
                    Label("\(g) g", systemImage: "scalemass.fill")
                        .font(.caption)
                }
                if let h = rec.heightCm {
                    Label(String(format: "%.1f cm", h), systemImage: "ruler.fill")
                        .font(.caption)
                }
                if let head = rec.headCircumferenceCm {
                    Label(String(format: "%.1f cm", head), systemImage: "circle.dotted")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func delete(at offsets: IndexSet) {
        let reversed = Array(records.reversed())
        for index in offsets {
            modelContext.delete(reversed[index])
        }
        try? modelContext.save()
    }
}
