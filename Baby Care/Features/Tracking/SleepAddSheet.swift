import SwiftUI
import SwiftData

struct SleepAddSheet: View {
    let babyID: UUID
    let editing: SleepRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .completed
    @State private var startedAt: Date = .now.addingTimeInterval(-30 * 60)
    @State private var endedAt: Date = .now
    @State private var isNap: Bool = true
    @State private var notes: String = ""

    @State private var errorMessage: String?

    enum Mode: String, CaseIterable {
        case completed = "Tamamlanmış"
        case ongoing = "Şu an başlat"
    }

    init(babyID: UUID, editing: SleepRecord? = nil) {
        self.babyID = babyID
        self.editing = editing
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    Section {
                        Picker("Kayıt Modu", selection: $mode) {
                            ForEach(Mode.allCases, id: \.self) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Zaman") {
                    DatePicker("Başlangıç", selection: $startedAt)
                    if mode == .completed {
                        DatePicker("Bitiş", selection: $endedAt, in: startedAt...)
                    }
                }

                Section("Tür") {
                    Picker("Uyku Türü", selection: $isNap) {
                        Text("Gündüz şekerleme").tag(true)
                        Text("Gece uykusu").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .completed {
                    Section {
                        let s = max(0, Int(endedAt.timeIntervalSince(startedAt)))
                        HStack {
                            Text("Toplam süre")
                            Spacer()
                            Text(DurationFormatter.string(fromSeconds: s))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: zor uyudu", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Uyku Düzenle" : "Uyku Ekle")
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
        guard let s = editing else { return }
        startedAt = s.startedAt
        endedAt = s.endedAt ?? .now
        mode = .completed
        isNap = s.isNap
        notes = s.notes ?? ""
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let existing = editing {
            existing.startedAt = startedAt
            existing.endedAt = endedAt
            existing.isNap = isNap
            existing.notes = cleanedNotes
            existing.updatedAt = .now
        } else {
            let record = SleepRecord(
                babyID: babyID,
                startedAt: mode == .ongoing ? .now : startedAt,
                endedAt: mode == .ongoing ? nil : endedAt,
                isNap: isNap,
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
