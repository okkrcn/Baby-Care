import SwiftUI
import SwiftData

struct VaccinationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SelectedBabyStore.self) private var babyStore

    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Query(sort: \VaccinationRecord.scheduledDate) private var allRecords: [VaccinationRecord]

    @State private var selectedRecord: VaccinationRecord?
    @State private var didAskPermission = false

    private var baby: Baby? { babyStore.resolved(from: babies) }

    private var records: [VaccinationRecord] {
        guard let id = baby?.id else { return [] }
        return allRecords.filter { $0.babyID == id }
    }

    private var upcoming: [VaccinationRecord] {
        records.filter { !$0.isCompleted && $0.daysFromToday >= 0 }
    }
    private var overdue: [VaccinationRecord] {
        records.filter { !$0.isCompleted && $0.daysFromToday < 0 }
    }
    private var completed: [VaccinationRecord] {
        records
            .filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? $0.scheduledDate) > ($1.completedDate ?? $1.scheduledDate) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if baby == nil {
                    ContentUnavailableView(
                        "Bebek bilgisi yok",
                        systemImage: "syringe.fill",
                        description: Text("Önce Bebek sekmesinden bir bebek ekleyin.")
                    )
                } else if records.isEmpty {
                    ContentUnavailableView {
                        Label("Aşı planı yok", systemImage: "syringe.fill")
                    } description: {
                        Text("Bebek için T.C. Sağlık Bakanlığı 2026 aşı takvimini şimdi oluşturun.")
                    } actions: {
                        Button {
                            generateScheduleForExistingBaby()
                        } label: {
                            Text("Takvim Oluştur").bold()
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)
                    }
                } else {
                    List {
                        if !overdue.isEmpty {
                            Section {
                                ForEach(overdue) { row($0) }
                            } header: {
                                Label("Geciken", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                        if !upcoming.isEmpty {
                            Section("Yaklaşan") {
                                ForEach(upcoming) { row($0) }
                            }
                        }

                        if !completed.isEmpty {
                            Section("Tamamlanan") {
                                ForEach(completed) { row($0) }
                            }
                        }

                        Section {
                            Text("Bu içerik [T.C. Sağlık Bakanlığı Genişletilmiş Bağışıklama Programı](https://hsgm.saglik.gov.tr/tr/asi-takvimi.html) 2026 verilerine dayanır. Bilgilendirme amaçlıdır; bebeğinizin özel takvimi için pediatristinize veya Aile Sağlığı Merkezi'ne danışın.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Aşı Takvimi")
            .toolbar {
                if babies.count > 1 {
                    ToolbarItem(placement: .principal) {
                        BabyPickerToolbarMenu(babies: babies, selected: baby)
                    }
                }
            }
            .sheet(item: $selectedRecord) { rec in
                VaccinationDetailView(record: rec, babyName: baby?.name ?? "")
            }
            .task {
                if !didAskPermission {
                    didAskPermission = true
                    _ = await NotificationService.requestAuthorizationIfNeeded()
                    if let name = baby?.name {
                        await NotificationService.rescheduleAll(for: name, records: records)
                    }
                }
            }
        }
    }

    private func generateScheduleForExistingBaby() {
        guard let b = baby else { return }
        VaccinationScheduler.generateSchedule(for: b, in: modelContext)
        Task {
            let updated = allRecords.filter { $0.babyID == b.id }
            await NotificationService.rescheduleAll(for: b.name, records: updated)
        }
    }

    @ViewBuilder
    private func row(_ rec: VaccinationRecord) -> some View {
        Button {
            selectedRecord = rec
        } label: {
            HStack(spacing: 12) {
                statusIcon(rec)
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.definition?.shortName ?? rec.vaccineDefinitionID)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle(for: rec))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if rec.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    badge(for: rec)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(_ rec: VaccinationRecord) -> some View {
        Group {
            if rec.isCompleted {
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
            } else if rec.daysFromToday < 0 {
                Image(systemName: "exclamationmark")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "syringe.fill")
                    .foregroundStyle(.pink)
            }
        }
    }

    private func subtitle(for rec: VaccinationRecord) -> String {
        if let done = rec.completedDate {
            return "Yapıldı: \(DateFormatters.displayDate.string(from: done))"
        }
        return "Planlanan: \(DateFormatters.displayDate.string(from: rec.scheduledDate))"
    }

    private func badge(for rec: VaccinationRecord) -> some View {
        let (text, color) = badgeContent(for: rec)
        return Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
    }

    private func badgeContent(for rec: VaccinationRecord) -> (String, Color) {
        let days = rec.daysFromToday
        if days < 0 {
            return ("\(-days) gün geçti", .red)
        } else if days == 0 {
            return ("Bugün", .orange)
        } else if days <= 7 {
            return ("\(days) gün kaldı", .orange)
        } else {
            return ("\(days) gün kaldı", .secondary)
        }
    }
}
