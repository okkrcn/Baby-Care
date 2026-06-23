import SwiftUI
import SwiftData

struct FeedingAddSheet: View {
    let babyID: UUID
    let editing: FeedingRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .completed
    @State private var type: FeedingType = .breast
    @State private var startedAt: Date = .now
    @State private var durationMinutes: Int = 15
    @State private var side: BreastSide = .left
    @State private var amountML: Int = 90
    @State private var notes: String = ""

    @State private var errorMessage: String?

    enum Mode: String, CaseIterable {
        case completed = "Tamamlanmış"
        case ongoing   = "Şu an başlat"
    }

    init(babyID: UUID, editing: FeedingRecord? = nil) {
        self.babyID = babyID
        self.editing = editing
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Beslenme Türü") {
                    Picker("Tür", selection: $type) {
                        ForEach(FeedingType.allCases, id: \.self) { t in
                            Text(t.localizedTitle).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if !isEditing && type == .breast {
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
                }

                if type == .breast {
                    Section("Emzirme") {
                        Picker("Göğüs", selection: $side) {
                            ForEach(BreastSide.allCases, id: \.self) { s in
                                Text(s.localizedTitle).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)

                        if mode == .completed || isEditing {
                            Stepper(value: $durationMinutes, in: 1...90, step: 1) {
                                HStack {
                                    Text("Süre")
                                    Spacer()
                                    Text("\(durationMinutes) dk")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Section("Biberon") {
                        Stepper(value: $amountML, in: 5...300, step: 5) {
                            HStack {
                                Text("Miktar")
                                Spacer()
                                Text("\(amountML) ml")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: kusma oldu", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Beslenme Düzenle" : "Beslenme Ekle")
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
        guard let f = editing else { return }
        type = f.type
        startedAt = f.startedAt
        if let dur = f.durationSeconds {
            durationMinutes = max(1, dur / 60)
        }
        if let s = f.side { side = s }
        if let ml = f.amountML { amountML = ml }
        notes = f.notes ?? ""
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if let existing = editing {
            existing.type = type
            existing.startedAt = startedAt
            existing.durationSeconds = type == .breast ? durationMinutes * 60 : nil
            existing.side = type == .breast ? side : nil
            existing.amountML = type.isBottle ? amountML : nil
            existing.notes = cleanedNotes
            existing.updatedAt = .now
        } else {
            let isOngoingBreast = (type == .breast && mode == .ongoing)
            let record = FeedingRecord(
                babyID: babyID,
                type: type,
                startedAt: isOngoingBreast ? .now : startedAt,
                endedAt: nil,
                durationSeconds: isOngoingBreast ? nil : (type == .breast ? durationMinutes * 60 : nil),
                side: type == .breast ? side : nil,
                amountML: type.isBottle ? amountML : nil,
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
