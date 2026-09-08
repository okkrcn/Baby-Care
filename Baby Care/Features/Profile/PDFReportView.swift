import SwiftUI
import Charts

/// PDF olarak render edilen rapor içeriği — bebeğin tüm tutulan verilerini kapsar.
/// Ekranda gösterilmek için tasarlanmamıştır; yalnızca PDFReportGenerator kullanır.
/// Çok sayfalı çıktıyı PDFReportGenerator pagination ile üretir.
struct PDFReportView: View {
    let baby: Baby
    let feedings: [FeedingRecord]      // tarihe göre azalan (yeni → eski)
    let sleeps: [SleepRecord]          // tarihe göre azalan
    let diapers: [DiaperRecord]        // tarihe göre azalan
    let growth: [GrowthRecord]         // tarihe göre artan
    let vaccinations: [VaccinationRecord]
    let medications: [Medication]
    let milkBatches: [BreastMilkBatch]  // tarihe göre azalan
    let solidFoods: [SolidFoodRecord]   // tarihe göre azalan
    let allergens: [AllergenIntroduction]

    private let cal = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            babySection
            trackingSummarySection
            chartsSection
            if !growth.isEmpty { growthSection }
            if !vaccinations.isEmpty { vaccinationSection }
            if !medications.isEmpty { medicationSection }
            if !milkBatches.isEmpty { milkSection }
            if !solidFoods.isEmpty || !allergens.isEmpty { solidFoodSection }
            recentLogsSection
            footer
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Baby Care — Bebek Bakım Raporu")
                    .font(.title2.bold())
                Spacer()
            }
            Text("Oluşturulma: \(dateTime(.now))")
                .font(.caption)
                .foregroundStyle(.gray)
            Divider()
        }
    }

    // MARK: - Baby

    private var babySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bebek Bilgileri").font(.headline)
            row("Ad", baby.name)
            row("Doğum Tarihi", DateFormatters.displayDate.string(from: baby.birthDate))
            row("Yaş", ageText)
            row("Cinsiyet", baby.sex.localizedTitle)
            if let w = baby.birthWeightGrams { row("Doğum Kilosu", "\(w) g") }
            if let l = baby.birthLengthCm { row("Doğum Boyu", String(format: "%.1f cm", l)) }
            Divider()
        }
    }

    private var ageText: String {
        let days = baby.ageInDays
        if days < 14 { return "\(days) günlük" }
        let weeks = baby.ageInWeeks
        if weeks < 12 { return "\(weeks) haftalık" }
        return "\(baby.ageInMonths) aylık"
    }

    // MARK: - Tracking summary

    private struct DayRow: Identifiable {
        let id = UUID()
        let date: Date
        let feeds: Int
        let ml: Int
        let sleepH: Double
        let diapers: Int
    }

    private var totalMl: Int { feedings.reduce(0) { $0 + ($1.amountML ?? 0) } }
    private var totalSleepSeconds: Int { sleeps.reduce(0) { $0 + $1.durationSeconds } }

    private var dailyRows: [DayRow] {
        let days = Set(
            feedings.map { cal.startOfDay(for: $0.startedAt) }
            + sleeps.map { cal.startOfDay(for: $0.startedAt) }
            + diapers.map { cal.startOfDay(for: $0.recordedAt) }
        )
        return days.sorted(by: >).prefix(30).map { day in
            let f = feedings.filter { cal.isDate($0.startedAt, inSameDayAs: day) }
            let s = sleeps.filter { cal.isDate($0.startedAt, inSameDayAs: day) }
            let d = diapers.filter { cal.isDate($0.recordedAt, inSameDayAs: day) }
            return DayRow(
                date: day,
                feeds: f.count,
                ml: f.reduce(0) { $0 + ($1.amountML ?? 0) },
                sleepH: Double(s.reduce(0) { $0 + $1.durationSeconds }) / 3600.0,
                diapers: d.count
            )
        }
    }

    private var trackingSummarySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Takip Özeti").font(.headline)
            row("Toplam beslenme", "\(feedings.count) öğün" + (totalMl > 0 ? " · \(totalMl) ml" : ""))
            row("Toplam uyku", DurationFormatter.string(fromSeconds: totalSleepSeconds))
            row("Toplam bez", "\(diapers.count) değişim")

            let rows = dailyRows
            if !rows.isEmpty {
                Text("Günlük Dağılım (son \(rows.count) gün)")
                    .font(.subheadline).bold()
                    .padding(.top, 4)
                HStack {
                    Text("Tarih").bold().frame(width: 110, alignment: .leading)
                    Text("Beslenme").bold().frame(width: 100, alignment: .leading)
                    Text("Uyku").bold().frame(width: 70, alignment: .leading)
                    Text("Bez").bold().frame(width: 50, alignment: .leading)
                }
                .font(.caption)
                ForEach(rows) { r in
                    HStack {
                        Text(DateFormatters.displayDate.string(from: r.date))
                            .frame(width: 110, alignment: .leading)
                        Text(r.ml > 0 ? "\(r.feeds) · \(r.ml)ml" : "\(r.feeds)")
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.1f sa", r.sleepH))
                            .frame(width: 70, alignment: .leading)
                        Text("\(r.diapers)")
                            .frame(width: 50, alignment: .leading)
                    }
                    .font(.caption)
                }
            }
            Divider()
        }
    }

    // MARK: - Charts

    private struct ChartDay: Identifiable {
        let id = UUID()
        let label: String
        let feeds: Int
        let diapers: Int
        let sleepH: Double
    }

    private struct MeasurePoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "EEE"
        return f
    }()

    private var last7: [ChartDay] {
        let today = cal.startOfDay(for: .now)
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: -6 + $0, to: today) }
        return days.map { day in
            ChartDay(
                label: Self.weekdayFormatter.string(from: day),
                feeds: feedings.filter { cal.isDate($0.startedAt, inSameDayAs: day) }.count,
                diapers: diapers.filter { cal.isDate($0.recordedAt, inSameDayAs: day) }.count,
                sleepH: Double(sleeps.filter { cal.isDate($0.startedAt, inSameDayAs: day) }.reduce(0) { $0 + $1.durationSeconds }) / 3600.0
            )
        }
    }

    private var weightPoints: [MeasurePoint] {
        growth.compactMap { g in g.weightGrams.map { MeasurePoint(date: g.recordedAt, value: Double($0) / 1000.0) } }
    }

    private var heightPoints: [MeasurePoint] {
        growth.compactMap { g in g.heightCm.map { MeasurePoint(date: g.recordedAt, value: $0) } }
    }

    @ViewBuilder
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grafikler").font(.headline)

            chartBlock(title: "Beslenme — son 7 gün (öğün)") {
                Chart(last7) { d in
                    BarMark(x: .value("Gün", d.label), y: .value("öğün", d.feeds))
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                }
            }

            chartBlock(title: "Bez — son 7 gün (adet)") {
                Chart(last7) { d in
                    BarMark(x: .value("Gün", d.label), y: .value("adet", d.diapers))
                        .foregroundStyle(Color.green.gradient)
                        .cornerRadius(4)
                }
            }

            chartBlock(title: "Uyku — son 7 gün (saat)") {
                Chart(last7) { d in
                    BarMark(x: .value("Gün", d.label), y: .value("saat", d.sleepH))
                        .foregroundStyle(Color.indigo.gradient)
                        .cornerRadius(4)
                }
            }

            if !weightPoints.isEmpty {
                chartBlock(title: "Kilo (kg)") {
                    Chart(weightPoints) { p in
                        LineMark(x: .value("Tarih", p.date), y: .value("kg", p.value))
                            .foregroundStyle(.pink)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Tarih", p.date), y: .value("kg", p.value))
                            .foregroundStyle(.pink)
                    }
                }
            }

            if !heightPoints.isEmpty {
                chartBlock(title: "Boy (cm)") {
                    Chart(heightPoints) { p in
                        LineMark(x: .value("Tarih", p.date), y: .value("cm", p.value))
                            .foregroundStyle(.orange)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Tarih", p.date), y: .value("cm", p.value))
                            .foregroundStyle(.orange)
                    }
                }
            }
            Divider()
        }
    }

    private func chartBlock<C: View>(title: String, @ViewBuilder chart: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.bold())
            chart()
                .frame(height: 150)
        }
    }

    // MARK: - Growth

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Büyüme Ölçümleri").font(.headline)
            HStack {
                Text("Tarih").bold().frame(width: 120, alignment: .leading)
                Text("Kilo").bold().frame(width: 80, alignment: .leading)
                Text("Boy").bold().frame(width: 80, alignment: .leading)
                Text("Baş Çevresi").bold().frame(width: 100, alignment: .leading)
            }
            .font(.caption)
            ForEach(growth) { g in
                HStack {
                    Text(DateFormatters.displayDate.string(from: g.recordedAt))
                        .frame(width: 120, alignment: .leading)
                    Text(g.weightGrams.map { "\($0) g" } ?? "—")
                        .frame(width: 80, alignment: .leading)
                    Text(g.heightCm.map { String(format: "%.1f cm", $0) } ?? "—")
                        .frame(width: 80, alignment: .leading)
                    Text(g.headCircumferenceCm.map { String(format: "%.1f cm", $0) } ?? "—")
                        .frame(width: 100, alignment: .leading)
                }
                .font(.caption)
            }
            Divider()
        }
    }

    // MARK: - Vaccination

    private var vaccinationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Aşı Takvimi").font(.headline)

            let completed = vaccinations.filter { $0.completedDate != nil }
            let pending = vaccinations.filter { $0.completedDate == nil }

            if !completed.isEmpty {
                Text("Tamamlanan").font(.subheadline).bold()
                ForEach(completed) { v in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green).font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(v.definition?.shortName ?? v.vaccineDefinitionID).font(.caption.bold())
                            if let done = v.completedDate {
                                Text("Yapıldı: \(DateFormatters.displayDate.string(from: done))")
                                    .font(.caption2).foregroundStyle(.gray)
                            }
                        }
                    }
                }
            }

            if !pending.isEmpty {
                Text("Yaklaşan / Bekleyen").font(.subheadline).bold()
                ForEach(pending) { v in
                    HStack(alignment: .top) {
                        Image(systemName: "circle").foregroundStyle(.orange).font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(v.definition?.shortName ?? v.vaccineDefinitionID).font(.caption.bold())
                            Text("Planlanan: \(DateFormatters.displayDate.string(from: v.scheduledDate))")
                                .font(.caption2).foregroundStyle(.gray)
                        }
                    }
                }
            }
            Divider()
        }
    }

    // MARK: - Medication

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vitamin & İlaç").font(.headline)
            ForEach(medications) { m in
                HStack(alignment: .top) {
                    Image(systemName: m.icon).foregroundStyle(.orange).font(.caption)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(m.name).font(.caption.bold())
                        Text(m.dosageText).font(.caption2).foregroundStyle(.gray)
                    }
                }
            }
            Divider()
        }
    }

    // MARK: - Solid food

    private var solidFoodSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ek Gıda").font(.headline)

            if !solidFoods.isEmpty {
                let distinctFoods = Set(solidFoods.flatMap(\.foodIDs)).count
                row("Toplam öğün", "\(solidFoods.count)")
                row("Denenen farklı besin", "\(distinctFoods)")
                if let first = solidFoods.last {
                    row("İlk ek gıda", dateTime(first.servedAt))
                }
            }

            let introduced = allergens.filter { $0.status != .notIntroduced }
            if !introduced.isEmpty {
                Text("Alerjen durumu").font(.caption.bold()).padding(.top, 2)
                ForEach(introduced) { intro in
                    HStack(alignment: .top) {
                        Text(intro.allergen.localizedTitle)
                            .font(.caption2)
                        Spacer()
                        Text(intro.status.localizedTitle)
                            .font(.caption2)
                            .foregroundStyle(intro.status == .reacted ? .red : .gray)
                    }
                }
                Text("Tepki gözlenen besin hekim değerlendirmesi olmadan evde tekrar denenmez.")
                    .font(.caption2).foregroundStyle(.gray).padding(.top, 1)
            }
            Divider()
        }
    }

    // MARK: - Milk storage

    private var milkSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Sağılmış Süt Saklama").font(.headline)
            ForEach(milkBatches) { b in
                let state = b.isUsed ? "kullanıldı" : (b.isExpired ? "süresi doldu" : "aktif")
                Text("• \(DateFormatters.displayDate.string(from: b.pumpedAt)) — \(b.amountML) ml · \(b.storage.localizedTitle) · \(state)")
                    .font(.caption2)
            }
            Divider()
        }
    }

    // MARK: - Recent detailed logs

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Son Kayıtlar (detay)").font(.headline)

            if !feedings.isEmpty {
                Text("Beslenme — son \(min(20, feedings.count))").font(.subheadline).bold()
                ForEach(feedings.prefix(20)) { f in
                    Text("• \(dateTime(f.startedAt)) — \(feedingDesc(f))").font(.caption2)
                }
            }
            if !sleeps.isEmpty {
                Text("Uyku — son \(min(20, sleeps.count))").font(.subheadline).bold().padding(.top, 2)
                ForEach(sleeps.prefix(20)) { s in
                    Text("• \(dateTime(s.startedAt)) — \(sleepDesc(s))").font(.caption2)
                }
            }
            if !diapers.isEmpty {
                Text("Bez — son \(min(20, diapers.count))").font(.subheadline).bold().padding(.top, 2)
                ForEach(diapers.prefix(20)) { d in
                    let extra = d.consistency.map { " (\($0.localizedTitle))" } ?? ""
                    Text("• \(dateTime(d.recordedAt)) — \(d.type.localizedTitle)\(extra)").font(.caption2)
                }
            }
            Divider()
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Kaynak: T.C. Sağlık Bakanlığı GBP 2026, DSÖ Çocuk Büyüme Standartları.")
                .font(.caption2).foregroundStyle(.gray)
            Text("Bu rapor bilgilendirme amaçlıdır, hekim değerlendirmesinin yerini tutmaz.")
                .font(.caption2).foregroundStyle(.gray)
            Text("Baby Care 1.0")
                .font(.caption2).foregroundStyle(.gray)
        }
    }

    // MARK: - Helpers

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key + ":")
                .font(.caption).foregroundStyle(.gray)
                .frame(width: 130, alignment: .leading)
            Text(value).font(.caption)
            Spacer()
        }
    }

    private func dateTime(_ date: Date) -> String {
        DateFormatters.displayDate.string(from: date) + " " + DateFormatters.displayTime.string(from: date)
    }

    private func feedingDesc(_ f: FeedingRecord) -> String {
        if let dur = f.durationSeconds {
            return "\(f.type.localizedTitle) · \(DurationFormatter.string(fromSeconds: dur))"
        }
        if let ml = f.amountML {
            return "\(f.type.localizedTitle) · \(ml) ml"
        }
        return f.type.localizedTitle
    }

    private func sleepDesc(_ s: SleepRecord) -> String {
        if s.isOngoing { return "Devam ediyor" }
        return "\(s.isNap ? "Gündüz" : "Gece") · \(DurationFormatter.string(fromSeconds: s.durationSeconds))"
    }
}
