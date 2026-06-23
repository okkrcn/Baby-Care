import SwiftUI
import SwiftData

struct BabyProfileEditView: View {
    let baby: Baby?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var birthDate: Date = .now
    @State private var hasBirthTime: Bool = false
    @State private var birthTime: Date = .now
    @State private var birthWeightGrams: Int? = nil
    @State private var birthLengthCm: Double? = nil
    @State private var sex: BabySex = .unspecified

    @State private var isWorking = false
    @State private var errorMessage: String?

    private var isEditing: Bool { baby != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ad") {
                    TextField("Bebeğin adı", text: $name)
                }

                Section("Doğum") {
                    DatePicker("Tarih", selection: $birthDate, displayedComponents: .date)
                    Toggle("Saat eklenecek", isOn: $hasBirthTime)
                    if hasBirthTime {
                        DatePicker("Saat", selection: $birthTime, displayedComponents: .hourAndMinute)
                    }
                    Picker("Cinsiyet", selection: $sex) {
                        ForEach(BabySex.allCases, id: \.self) { s in
                            Text(s.localizedTitle).tag(s)
                        }
                    }
                }

                Section("Ölçümler") {
                    HStack {
                        Text("Doğum Kilosu (g)"); Spacer()
                        TextField("3200", value: $birthWeightGrams, format: .number)
                            .numericKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Doğum Boyu (cm)"); Spacer()
                        TextField("50", value: $birthLengthCm, format: .number)
                            .decimalKeyboard()
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Bebeği Düzenle" : "Yeni Bebek")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(!canSave || isWorking)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func load() {
        guard let b = baby else { return }
        name = b.name
        birthDate = b.birthDate
        if let t = b.birthTime {
            hasBirthTime = true
            birthTime = t
        }
        birthWeightGrams = b.birthWeightGrams
        birthLengthCm = b.birthLengthCm
        sex = b.sex
    }

    private func save() {
        isWorking = true
        defer { isWorking = false }
        errorMessage = nil

        var newBaby: Baby?
        if let existing = baby {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.birthDate = birthDate
            existing.birthTime = hasBirthTime ? birthTime : nil
            existing.birthWeightGrams = birthWeightGrams
            existing.birthLengthCm = birthLengthCm
            existing.sex = sex
            existing.updatedAt = .now
        } else {
            let new = Baby(
                name: name.trimmingCharacters(in: .whitespaces),
                birthDate: birthDate,
                birthTime: hasBirthTime ? birthTime : nil,
                birthWeightGrams: birthWeightGrams,
                birthLengthCm: birthLengthCm,
                sex: sex
            )
            modelContext.insert(new)
            newBaby = new
        }

        do {
            try modelContext.save()
            if let new = newBaby {
                BabyOnboardingService.setupNewBaby(new, in: modelContext)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
