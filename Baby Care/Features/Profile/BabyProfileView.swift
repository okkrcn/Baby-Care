import SwiftUI
import SwiftData

struct BabyProfileView: View {
    @Environment(SelectedBabyStore.self) private var babyStore
    @Query(sort: \Baby.birthDate) private var babies: [Baby]
    @Query(sort: \GrowthRecord.recordedAt) private var allGrowth: [GrowthRecord]
    @Query(sort: \VaccinationRecord.scheduledDate) private var allVaccinations: [VaccinationRecord]
    @Query(sort: \Medication.createdAt) private var allMedications: [Medication]
    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]
    @Query(sort: \SleepRecord.startedAt, order: .reverse) private var allSleeps: [SleepRecord]
    @Query(sort: \DiaperRecord.recordedAt, order: .reverse) private var allDiapers: [DiaperRecord]
    @Query(sort: \BreastMilkBatch.pumpedAt, order: .reverse) private var allMilk: [BreastMilkBatch]
    @Query(sort: \SolidFoodRecord.servedAt, order: .reverse) private var allSolids: [SolidFoodRecord]
    @Query private var allAllergens: [AllergenIntroduction]

    @Environment(\.modelContext) private var modelContext

    @State private var showEdit = false
    @State private var editingBaby: Baby?
    @State private var pdfURL: URL?
    @State private var pdfBabyName: String = ""
    @State private var deleteCandidate: Baby?

    var body: some View {
        NavigationStack {
            List {
                ForEach(babies) { baby in
                    Section {
                        babyRow(baby)
                    }

                    Section("Detaylar") {
                        NavigationLink {
                            GrowthView(baby: baby)
                        } label: {
                            Label("Büyüme & Ölçümler", systemImage: "chart.line.uptrend.xyaxis")
                        }

                        NavigationLink {
                            GuideView(baby: baby)
                        } label: {
                            Label("Gelişim Rehberi", systemImage: "book.fill")
                        }

                        NavigationLink {
                            MedicationView(baby: baby)
                        } label: {
                            Label("Vitamin & İlaç", systemImage: "pills.fill")
                        }

                        if baby.stage.isSolidFoodAge {
                            NavigationLink {
                                SolidFoodView(baby: baby)
                            } label: {
                                Label("Ek Gıda", systemImage: "carrot.fill")
                            }
                        }

                        NavigationLink {
                            FeedingCalculatorView(baby: baby)
                        } label: {
                            Label("Beslenme Hesabı", systemImage: "function")
                        }

                        NavigationLink {
                            MilkStorageView(baby: baby)
                        } label: {
                            Label("Süt Sağma & Saklama", systemImage: "drop.triangle.fill")
                        }

                        NavigationLink {
                            WeeklySummaryView(baby: baby)
                        } label: {
                            Label("Haftalık Özet", systemImage: "calendar.badge.clock")
                        }

                        Button {
                            generatePDF(for: baby)
                        } label: {
                            Label("PDF Rapor Oluştur", systemImage: "doc.richtext")
                        }

                        Button(role: .destructive) {
                            deleteCandidate = baby
                        } label: {
                            Label("Bebeği Sil", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .navigationTitle("Bebek")
            .confirmationDialog(
                deleteCandidate.map { "\($0.name) silinsin mi?" } ?? "Sil",
                isPresented: Binding(
                    get: { deleteCandidate != nil },
                    set: { if !$0 { deleteCandidate = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Bebeği ve Tüm Kayıtlarını Sil", role: .destructive) {
                    if let baby = deleteCandidate {
                        Task { await deleteBaby(baby) }
                    }
                }
                Button("Vazgeç", role: .cancel) {
                    deleteCandidate = nil
                }
            } message: {
                Text("Bu işlem bebek profilini, tüm beslenme/uyku/bez/aşı/büyüme/vitamin/süt kayıtlarını ve bildirimleri kalıcı olarak siler. Geri alınamaz.")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingBaby = nil
                        showEdit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                BabyProfileEditView(baby: editingBaby)
            }
            .sheet(item: $pdfURL) { url in
                PDFShareSheet(url: url, suggestedName: pdfBabyName)
            }
        }
    }

    @ViewBuilder
    private func babyRow(_ baby: Baby) -> some View {
        let isSelected = baby.id == babyStore.resolved(from: babies)?.id

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.title)
                    .foregroundStyle(.pink.gradient)
                VStack(alignment: .leading) {
                    HStack {
                        Text(baby.name)
                            .font(.title3.bold())
                        if isSelected && babies.count > 1 {
                            Text("Seçili")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.pink.opacity(0.15), in: .capsule)
                                .foregroundStyle(.pink)
                        }
                    }
                    Text(ageDescription(baby))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    editingBaby = baby
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
            }

            if babies.count > 1 && !isSelected {
                Button {
                    babyStore.select(baby)
                } label: {
                    Label("Bu bebeği seç", systemImage: "checkmark.circle")
                        .font(.footnote)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Divider()

            HStack(spacing: 16) {
                infoTile("Doğum", DateFormatters.displayDate.string(from: baby.birthDate))
                if let w = baby.birthWeightGrams {
                    infoTile("Kilo", "\(w) g")
                }
                if let l = baby.birthLengthCm {
                    infoTile("Boy", String(format: "%.1f cm", l))
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .onTapGesture {
            babyStore.select(baby)
        }
    }

    private func infoTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.medium))
        }
    }

    private func ageDescription(_ baby: Baby) -> String {
        let days = baby.ageInDays
        if days < 14 { return "\(days) günlük" }
        let weeks = baby.ageInWeeks
        if weeks < 12 { return "\(weeks) haftalık" }
        return "\(baby.ageInMonths) aylık"
    }

    private func deleteBaby(_ baby: Baby) async {
        await BabyDeleteService.delete(baby, from: modelContext)
        deleteCandidate = nil
    }

    private func generatePDF(for baby: Baby) {
        let id = baby.id
        let feedings = allFeedings.filter { $0.babyID == id }
        let sleeps = allSleeps.filter { $0.babyID == id }
        let diapers = allDiapers.filter { $0.babyID == id }
        let growth = allGrowth.filter { $0.babyID == id }
        let vaccs = allVaccinations.filter { $0.babyID == id }
        let meds = allMedications.filter { $0.babyID == id && $0.endedAt == nil }
        let milk = allMilk.filter { $0.babyID == id }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStamp = df.string(from: .now)
        let safeName = baby.name.replacingOccurrences(of: " ", with: "_")

        let url = PDFReportGenerator.generate(fileName: "BabyCare_\(safeName)_\(dateStamp)") {
            PDFReportView(
                baby: baby,
                feedings: feedings,
                sleeps: sleeps,
                diapers: diapers,
                growth: growth,
                vaccinations: vaccs,
                medications: meds,
                milkBatches: milk,
                solidFoods: allSolids.filter { $0.babyID == baby.id },
                allergens: allAllergens.filter { $0.babyID == baby.id }
                    .sorted {
                        let l = Allergen.allCases.firstIndex(of: $0.allergen) ?? 0
                        let r = Allergen.allCases.firstIndex(of: $1.allergen) ?? 0
                        return l < r
                    }
            )
        }
        if let url {
            pdfBabyName = baby.name
            pdfURL = url
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

#if os(iOS)
import UIKit

struct PDFShareSheet: UIViewControllerRepresentable {
    let url: URL
    let suggestedName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct PDFShareSheet: View {
    let url: URL
    let suggestedName: String
    var body: some View {
        ShareLink(item: url) { Label("Paylaş", systemImage: "square.and.arrow.up") }
            .padding()
    }
}
#endif
