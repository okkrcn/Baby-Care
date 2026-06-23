import SwiftUI
import SwiftData

struct GrowthAddSheet: View {
    let babyID: UUID
    let editing: GrowthRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var recordedAt: Date = .now
    @State private var weightGrams: Int? = nil
    @State private var heightCm: Double? = nil
    @State private var headCm: Double? = nil
    @State private var notes: String = ""
    @State private var errorMessage: String?

    init(babyID: UUID, editing: GrowthRecord? = nil) {
        self.babyID = babyID
        self.editing = editing
    }

    private var isEditing: Bool { editing != nil }

    private var hasAnyValue: Bool {
        weightGrams != nil || heightCm != nil || headCm != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarih") {
                    DatePicker("Ölçüm tarihi", selection: $recordedAt, displayedComponents: .date)
                }

                Section("Ölçümler") {
                    HStack {
                        Text("Kilo (g)"); Spacer()
                        TextField("4500", value: $weightGrams, format: .number)
                            .numericKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Boy (cm)"); Spacer()
                        TextField("55.0", value: $heightCm, format: .number)
                            .decimalKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Baş Çevresi (cm)"); Spacer()
                        TextField("36.0", value: $headCm, format: .number)
                            .decimalKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: 4. ay kontrolü", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Ölçüm Düzenle" : "Yeni Ölçüm")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(!hasAnyValue)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let g = editing else { return }
        recordedAt = g.recordedAt
        weightGrams = g.weightGrams
        heightCm = g.heightCm
        headCm = g.headCircumferenceCm
        notes = g.notes ?? ""
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let existing = editing {
            existing.recordedAt = recordedAt
            existing.weightGrams = weightGrams
            existing.heightCm = heightCm
            existing.headCircumferenceCm = headCm
            existing.notes = cleanedNotes
            existing.updatedAt = .now
        } else {
            let record = GrowthRecord(
                babyID: babyID,
                recordedAt: recordedAt,
                weightGrams: weightGrams,
                heightCm: heightCm,
                headCircumferenceCm: headCm,
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
