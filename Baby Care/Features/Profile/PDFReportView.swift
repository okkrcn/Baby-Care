import SwiftUI

/// PDF olarak render edilen sayfa içeriği.
/// Ekranda gösterilmek için tasarlanmamıştır — sadece PDFReportGenerator tarafından kullanılır.
struct PDFReportView: View {
    let baby: Baby
    let growth: [GrowthRecord]
    let vaccinations: [VaccinationRecord]
    let medications: [Medication]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            babySection
            if !growth.isEmpty { growthSection }
            if !vaccinations.isEmpty { vaccinationSection }
            if !medications.isEmpty { medicationSection }
            footer
        }
        .foregroundStyle(.black)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.title)
                    .foregroundStyle(.pink)
                Text("Baby Care — Bebek Bakım Raporu")
                    .font(.title2.bold())
                Spacer()
            }
            Text("Oluşturulma: \(DateFormatters.displayDate.string(from: .now))")
                .font(.caption)
                .foregroundStyle(.gray)
            Divider()
        }
    }

    private var babySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Bebek Bilgileri")
                .font(.headline)
            row("Ad", baby.name)
            row("Doğum Tarihi", DateFormatters.displayDate.string(from: baby.birthDate))
            row("Yaş", ageText)
            row("Cinsiyet", baby.sex.localizedTitle)
            if let w = baby.birthWeightGrams {
                row("Doğum Kilosu", "\(w) g")
            }
            if let l = baby.birthLengthCm {
                row("Doğum Boyu", String(format: "%.1f cm", l))
            }
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

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Büyüme Ölçümleri")
                .font(.headline)
            HStack {
                Text("Tarih").bold().frame(width: 120, alignment: .leading)
                Text("Kilo").bold().frame(width: 80, alignment: .leading)
                Text("Boy").bold().frame(width: 80, alignment: .leading)
                Text("Baş Çevresi").bold().frame(width: 100, alignment: .leading)
            }
            .font(.caption)
            ForEach(growth.suffix(10)) { g in
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

    private var vaccinationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Aşı Takvimi")
                .font(.headline)

            let completed = vaccinations.filter { $0.completedDate != nil }
            let pending = vaccinations.filter { $0.completedDate == nil }

            if !completed.isEmpty {
                Text("Tamamlanan").font(.subheadline).bold()
                ForEach(completed) { v in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(v.definition?.shortName ?? v.vaccineDefinitionID)
                                .font(.caption.bold())
                            if let done = v.completedDate {
                                Text("Yapıldı: \(DateFormatters.displayDate.string(from: done))")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
            }

            if !pending.isEmpty {
                Text("Yaklaşan / Bekleyen").font(.subheadline).bold()
                ForEach(pending) { v in
                    HStack(alignment: .top) {
                        Image(systemName: "circle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(v.definition?.shortName ?? v.vaccineDefinitionID)
                                .font(.caption.bold())
                            Text("Planlanan: \(DateFormatters.displayDate.string(from: v.scheduledDate))")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            Divider()
        }
    }

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vitamin & İlaç")
                .font(.headline)
            ForEach(medications) { m in
                HStack(alignment: .top) {
                    Image(systemName: m.icon)
                        .foregroundStyle(.orange)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(m.name).font(.caption.bold())
                        Text(m.dosageText).font(.caption2).foregroundStyle(.gray)
                    }
                }
            }
            Divider()
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key + ":")
                .font(.caption)
                .foregroundStyle(.gray)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.caption)
            Spacer()
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Kaynak: T.C. Sağlık Bakanlığı GBP 2026, DSÖ Çocuk Büyüme Standartları.")
                .font(.caption2)
                .foregroundStyle(.gray)
            Text("Bu rapor bilgilendirme amaçlıdır, hekim değerlendirmesinin yerini tutmaz.")
                .font(.caption2)
                .foregroundStyle(.gray)
            Text("Baby Care 1.0")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}
