import SwiftUI
import SwiftData

struct MilkBatchAddSheet: View {
    let babyID: UUID
    let babyName: String
    let editing: BreastMilkBatch?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amountML: Int = 100
    @State private var pumpedAt: Date = .now
    @State private var storage: MilkStorageLocation = .fridge
    @State private var notes: String = ""
    @State private var errorMessage: String?

    init(babyID: UUID, babyName: String, editing: BreastMilkBatch? = nil) {
        self.babyID = babyID
        self.babyName = babyName
        self.editing = editing
    }

    private var isEditing: Bool { editing != nil }

    private var calculatedExpiry: Date {
        pumpedAt.addingTimeInterval(TimeInterval(storage.maxHours * 3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Miktar") {
                    Stepper(value: $amountML, in: 5...500, step: 5) {
                        HStack {
                            Text("Miktar")
                            Spacer()
                            Text("\(amountML) ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Sağma Zamanı") {
                    DatePicker("Tarih ve saat", selection: $pumpedAt)
                }

                Section("Saklama Yeri") {
                    ForEach(MilkStorageLocation.allCases, id: \.self) { location in
                        Button {
                            storage = location
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: location.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(location.localizedTitle)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(location.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if storage == location {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    HStack {
                        Text("Otomatik Bitiş")
                        Spacer()
                        Text(DateFormatters.displayDate.string(from: calculatedExpiry))
                            .foregroundStyle(.secondary)
                            .font(.subheadline.monospacedDigit())
                    }
                    Text("Bitişine 30 dakika kala bildirim gönderilir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Not (isteğe bağlı)") {
                    TextField("Örn: sol göğüsten 80 ml", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Düzenle" : "Yeni Süt Kaydı")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
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
        guard let b = editing else { return }
        amountML = b.amountML
        pumpedAt = b.pumpedAt
        storage = b.storage
        notes = b.notes ?? ""
    }

    private func save() async {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedNotes = trimmed.isEmpty ? nil : trimmed

        let batch: BreastMilkBatch
        if let existing = editing {
            existing.amountML = amountML
            existing.pumpedAt = pumpedAt
            existing.storage = storage
            existing.expiresAt = calculatedExpiry
            existing.notes = cleanedNotes
            existing.updatedAt = .now
            batch = existing
        } else {
            let new = BreastMilkBatch(
                babyID: babyID,
                pumpedAt: pumpedAt,
                amountML: amountML,
                storage: storage,
                notes: cleanedNotes
            )
            modelContext.insert(new)
            batch = new
        }

        do {
            try modelContext.save()
            await NotificationService.scheduleExpiryReminder(for: batch, babyName: babyName)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
