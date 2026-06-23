import SwiftUI
import SwiftData

struct MedicationView: View {
    let baby: Baby

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Medication.createdAt) private var allMedications: [Medication]
    @Query(sort: \MedicationDose.takenAt, order: .reverse) private var allDoses: [MedicationDose]

    @State private var showAddSheet = false
    @State private var editingMedication: Medication?

    private var medications: [Medication] {
        allMedications.filter { $0.babyID == baby.id && $0.endedAt == nil }
    }

    private var todaysDoses: [MedicationDose] {
        allDoses.filter { Calendar.current.isDateInToday($0.takenAt) }
    }

    private func doseGivenToday(for med: Medication) -> Bool {
        todaysDoses.contains { $0.medicationID == med.id }
    }

    var body: some View {
        List {
            if medications.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Henüz ilaç eklenmedi",
                        systemImage: "pills.fill",
                        description: Text("D vitamini, demir damlası gibi günlük rutinleri ekleyebilirsiniz.")
                    )
                }
            } else {
                Section("Bugün") {
                    ForEach(medications) { med in
                        row(med)
                    }
                }
            }

            Section {
                Text("İlaç ve vitamin önerileri için pediatristinize danışın. Uygulama yalnızca rutini takip etmenize yardımcı olur, doz/öneri sağlamaz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Vitamin & İlaç")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MedicationAddSheet(babyID: baby.id, babyName: baby.name)
        }
        .sheet(item: $editingMedication) { med in
            MedicationAddSheet(babyID: baby.id, babyName: baby.name, editing: med)
        }
    }

    @ViewBuilder
    private func row(_ med: Medication) -> some View {
        let given = doseGivenToday(for: med)

        HStack(spacing: 12) {
            Image(systemName: med.icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(.orange.opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(.subheadline.weight(.medium))
                Text(med.dosageText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "Hatırlatma: %02d:%02d", med.reminderHour, med.reminderMinute))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                toggleDose(for: med, given: given)
            } label: {
                Image(systemName: given ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(given ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(.rect)
        .contextMenu {
            Button {
                editingMedication = med
            } label: {
                Label("Düzenle", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task { await delete(med) }
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    private func toggleDose(for med: Medication, given: Bool) {
        if given {
            if let existing = todaysDoses.first(where: { $0.medicationID == med.id }) {
                modelContext.delete(existing)
            }
        } else {
            let dose = MedicationDose(medicationID: med.id)
            modelContext.insert(dose)
        }
        try? modelContext.save()
    }

    private func delete(_ med: Medication) async {
        await NotificationService.cancelReminders(for: med)
        modelContext.delete(med)
        try? modelContext.save()
    }
}
