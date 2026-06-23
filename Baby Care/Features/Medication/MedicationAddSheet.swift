import SwiftUI
import SwiftData

struct MedicationAddSheet: View {
    let babyID: UUID
    let babyName: String
    let editing: Medication?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var dosageText: String = ""
    @State private var iconChoice: String = "pills.fill"
    @State private var reminderTime: Date = Calendar.current.date(
        bySettingHour: 10, minute: 0, second: 0, of: .now
    ) ?? .now
    @State private var notes: String = ""
    @State private var errorMessage: String?

    private let iconChoices: [(String, String)] = [
        ("pills.fill", "İlaç"),
        ("sun.max.fill", "D Vitamini"),
        ("drop.fill", "Damla"),
        ("syringe.fill", "Şurup"),
        ("leaf.fill", "Doğal"),
        ("cross.case.fill", "Genel"),
    ]

    init(babyID: UUID, babyName: String, editing: Medication? = nil) {
        self.babyID = babyID
        self.babyName = babyName
        self.editing = editing
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ad") {
                    TextField("Örn: D Vitamini", text: $name)
                }

                Section("Doz") {
                    TextField("Örn: Günde 3 damla (400 IU)", text: $dosageText)
                }

                Section("Simge") {
                    Picker("Simge", selection: $iconChoice) {
                        ForEach(iconChoices, id: \.0) { icon, label in
                            Label(label, systemImage: icon).tag(icon)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Günlük Hatırlatma") {
                    DatePicker("Saat", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    Text("Her gün belirttiğiniz saatte bildirim gönderilir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: aç karna verilir", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Düzenle" : "Yeni İlaç/Vitamin")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task { await save() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let m = editing else { return }
        name = m.name
        dosageText = m.dosageText
        iconChoice = m.icon
        notes = m.notes ?? ""
        if let date = Calendar.current.date(bySettingHour: m.reminderHour, minute: m.reminderMinute, second: 0, of: .now) {
            reminderTime = date
        }
    }

    private func save() async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = comps.hour ?? 10
        let minute = comps.minute ?? 0

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        let medication: Medication
        if let existing = editing {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.dosageText = dosageText
            existing.icon = iconChoice
            existing.reminderHour = hour
            existing.reminderMinute = minute
            existing.notes = cleanedNotes
            existing.updatedAt = .now
            medication = existing
        } else {
            let new = Medication(
                babyID: babyID,
                name: name.trimmingCharacters(in: .whitespaces),
                dosageText: dosageText,
                icon: iconChoice,
                reminderHour: hour,
                reminderMinute: minute,
                notes: cleanedNotes
            )
            modelContext.insert(new)
            medication = new
        }

        do {
            try modelContext.save()
            await NotificationService.scheduleDailyReminder(for: medication, babyName: babyName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
