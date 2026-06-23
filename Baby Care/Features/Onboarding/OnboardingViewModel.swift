import Foundation
import SwiftData

@MainActor
@Observable
final class OnboardingViewModel {
    var babyName: String = ""
    var birthDate: Date = .now
    var hasBirthTime: Bool = false
    var birthTime: Date = .now
    var birthWeightGrams: Int? = nil
    var birthLengthCm: Double? = nil
    var sex: BabySex = .unspecified

    var isWorking: Bool = false
    var errorMessage: String?
    var didFinish: Bool = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var canSaveBaby: Bool {
        !babyName.trimmingCharacters(in: .whitespaces).isEmpty && !isWorking
    }

    func saveBaby() {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        let baby = Baby(
            name: babyName.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            birthTime: hasBirthTime ? birthTime : nil,
            birthWeightGrams: birthWeightGrams,
            birthLengthCm: birthLengthCm,
            sex: sex
        )

        modelContext.insert(baby)

        do {
            try modelContext.save()
            BabyOnboardingService.setupNewBaby(baby, in: modelContext)
            didFinish = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
