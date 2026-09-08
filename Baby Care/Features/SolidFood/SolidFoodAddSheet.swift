import SwiftUI
import SwiftData

/// Katı gıda öğünü ekleme / düzenleme formu.
///
/// `FeedingAddSheet` yalnız `babyID` alır; bu form yaş bariyeri uyarısı
/// gösterebilmek için bebeğin kendisine ihtiyaç duyar.
struct SolidFoodAddSheet: View {
    let baby: Baby
    let editing: SolidFoodRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFoodIDs: Set<String> = []
    @State private var customName = ""
    @State private var method: SolidFoodMethod = .puree
    @State private var servedAt: Date = .now
    @State private var amount: SolidFoodAmount = .some
    @State private var reaction: SolidFoodReaction = .neutral
    @State private var notes = ""
    @State private var errorMessage: String?

    init(baby: Baby, editing: SolidFoodRecord? = nil) {
        self.baby = baby
        self.editing = editing
        if let editing {
            _selectedFoodIDs = State(initialValue: Set(editing.foodIDs))
            _customName = State(initialValue: editing.customFoodName ?? "")
            _method = State(initialValue: editing.method)
            _servedAt = State(initialValue: editing.servedAt)
            _amount = State(initialValue: editing.amount)
            _reaction = State(initialValue: editing.reaction)
            _notes = State(initialValue: editing.notes ?? "")
        }
    }

    private var selectedFoods: [FoodItem] {
        selectedFoodIDs.compactMap { FoodCatalog.item(id: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Bebeğin yaşı için henüz uygun olmayan seçimler.
    private var barredFoods: [FoodItem] {
        selectedFoods.filter { item in
            if let barrier = item.ageBarrier, baby.ageInMonths < barrier.minAgeMonths { return true }
            return baby.ageInMonths < item.minAgeMonths
        }
    }

    private var canSave: Bool {
        !selectedFoodIDs.isEmpty || !customName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                foodSection

                if !barredFoods.isEmpty {
                    ageWarningSection
                }

                Section("Sunum") {
                    Picker("Sunum", selection: $method) {
                        ForEach(SolidFoodMethod.allCases, id: \.self) { m in
                            Text(m.localizedTitle).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    DatePicker("Saat", selection: $servedAt)

                    Picker("Ne kadar yedi", selection: $amount) {
                        ForEach(SolidFoodAmount.allCases, id: \.self) { a in
                            Text(a.localizedTitle).tag(a)
                        }
                    }

                    Picker("Tepki", selection: $reaction) {
                        ForEach(SolidFoodReaction.allCases, id: \.self) { r in
                            Label(r.localizedTitle, systemImage: r.icon).tag(r)
                        }
                    }
                }

                if reaction == .adverse {
                    adverseReactionSection
                }

                Section("Not") {
                    TextField("İsteğe bağlı", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section {
                    Text("Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(editing == nil ? "Ek Gıda" : "Öğünü Düzenle")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("Kaydedilemedi", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Bölümler

    private var foodSection: some View {
        Section {
            ForEach(selectedFoods) { item in
                HStack(spacing: 8) {
                    Text(item.name)
                    Spacer()
                    if item.isIronRich {
                        Text("Demir")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.brown)
                    }
                    if item.chokingRisk == .high {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    selectedFoodIDs.remove(selectedFoods[index].id)
                }
            }

            NavigationLink {
                FoodLibraryView(baby: baby, selection: $selectedFoodIDs)
            } label: {
                Label("Besin ekle", systemImage: "plus.circle.fill")
            }

            TextField("Katalogda olmayan besin", text: $customName)
        } header: {
            Text("Besin")
        } footer: {
            if selectedFoodIDs.isEmpty && customName.isEmpty {
                Text("En az bir besin seçin veya adını yazın.")
            }
        }
    }

    private var ageWarningSection: some View {
        Section {
            ForEach(barredFoods) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Label(item.name, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    if let barrier = item.ageBarrier {
                        Text(barrier.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Bu besin \(item.minAgeMonths). aydan itibaren öneriliyor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Yaş uyarısı")
        } footer: {
            Text("Kaydı yine de tutabilirsiniz — bu bir takip aracıdır, karar sizindir.")
        }
    }

    private var adverseReactionSection: some View {
        Section {
            NavigationLink {
                SymptomDetailView(category: SymptomCatalog.alerjikReaksiyon)
            } label: {
                Label("Alerjik reaksiyon belirtileri", systemImage: "cross.case.fill")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("Nefes darlığı, hırıltı, dudak veya dil şişmesi ya da ani halsizlik varsa hemen 112'yi arayın.")
        }
    }

    // MARK: - Kaydetme

    private func save() {
        let trimmedCustom = customName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        do {
            if let editing {
                editing.foodIDs = Array(selectedFoodIDs)
                editing.customFoodName = trimmedCustom.isEmpty ? nil : trimmedCustom
                editing.method = method
                editing.servedAt = servedAt
                editing.amount = amount
                editing.reaction = reaction
                editing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                editing.updatedAt = .now
                try modelContext.save()
            } else {
                try SolidFoodService.log(
                    foodIDs: Array(selectedFoodIDs),
                    customName: trimmedCustom.isEmpty ? nil : trimmedCustom,
                    method: method,
                    amount: amount,
                    reaction: reaction,
                    servedAt: servedAt,
                    notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                    for: baby,
                    in: modelContext
                )
            }
            Haptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
