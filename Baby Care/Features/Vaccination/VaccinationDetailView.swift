import SwiftUI
import SwiftData

struct VaccinationDetailView: View {
    @Bindable var record: VaccinationRecord
    let babyName: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String = ""
    @State private var completedDate: Date = .now
    @State private var isCompleted: Bool = false
    @State private var scheduledDate: Date = .now

    private var definition: VaccineDefinition? { record.definition }

    var body: some View {
        NavigationStack {
            Form {
                if let def = definition {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(def.fullName)
                                .font(.headline)
                            Text(def.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Label(def.route, systemImage: "cross.case.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Planlanan Tarih") {
                    DatePicker(
                        "Tarih",
                        selection: $scheduledDate,
                        displayedComponents: .date
                    )
                }

                Section {
                    Toggle("Yapıldı olarak işaretle", isOn: $isCompleted)
                    if isCompleted {
                        DatePicker(
                            "Yapılış tarihi",
                            selection: $completedDate,
                            displayedComponents: .date
                        )
                    }
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: hafif ateş yaptı", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Text("Bilgilendirme amaçlıdır. Aşılar Aile Sağlığı Merkezi veya hastanelerde ücretsiz yapılır.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(definition?.shortName ?? "Aşı")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task { await save() }
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        notes = record.notes ?? ""
        scheduledDate = record.scheduledDate
        if let done = record.completedDate {
            isCompleted = true
            completedDate = done
        } else {
            isCompleted = false
            completedDate = .now
        }
    }

    private func save() async {
        record.scheduledDate = scheduledDate
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        record.notes = trimmed.isEmpty ? nil : trimmed
        record.completedDate = isCompleted ? completedDate : nil
        record.updatedAt = .now

        try? modelContext.save()

        if record.completedDate != nil {
            await NotificationService.cancelReminders(for: record)
        } else {
            await NotificationService.scheduleReminders(for: record, babyName: babyName)
        }

        dismiss()
    }
}
