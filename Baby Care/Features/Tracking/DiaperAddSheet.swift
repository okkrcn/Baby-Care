import SwiftUI
import SwiftData

struct DiaperAddSheet: View {
    let babyID: UUID
    let editing: DiaperRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: DiaperType = .pee
    @State private var recordedAt: Date = .now
    @State private var consistency: PooConsistency = .normal
    @State private var notes: String = ""

    @State private var errorMessage: String?

    init(babyID: UUID, editing: DiaperRecord? = nil) {
        self.babyID = babyID
        self.editing = editing
    }

    private var isEditing: Bool { editing != nil }

    private var requiresConsistency: Bool {
        type == .poo || type == .both
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tür") {
                    Picker("Tür", selection: $type) {
                        ForEach(DiaperType.allCases, id: \.self) { t in
                            Text(t.localizedTitle).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Zaman") {
                    DatePicker("Saat", selection: $recordedAt)
                }

                if requiresConsistency {
                    Section("Kıvam") {
                        Picker("Kıvam", selection: $consistency) {
                            ForEach(PooConsistency.allCases, id: \.self) { c in
                                Text(c.localizedTitle).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: yeşilimsi renk", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Bez Düzenle" : "Bez Değişimi")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let d = editing else { return }
        type = d.type
        recordedAt = d.recordedAt
        if let c = d.consistency { consistency = c }
        notes = d.notes ?? ""
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let existing = editing {
            existing.type = type
            existing.recordedAt = recordedAt
            existing.consistency = requiresConsistency ? consistency : nil
            existing.notes = cleanedNotes
            existing.updatedAt = .now
        } else {
            let record = DiaperRecord(
                babyID: babyID,
                recordedAt: recordedAt,
                type: type,
                consistency: requiresConsistency ? consistency : nil,
                notes: cleanedNotes
            )
            modelContext.insert(record)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
