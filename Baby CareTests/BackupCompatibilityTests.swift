import Testing
import Foundation
@testable import Baby_Care

struct BackupCompatibilityTests {

    /// Sürüm 1 formatında, yeni alanları içermeyen bir yedek.
    /// Bu metin gerçek bir 1.4.1 yedeğinin yapısıdır; değiştirmeyin.
    private let v1JSON = """
    {
      "version": 1,
      "exportedAt": "2026-01-15T10:00:00Z",
      "appVersion": "1.4.1",
      "babies": [{
        "id": "11111111-1111-1111-1111-111111111111",
        "name": "Deniz",
        "birthDate": "2025-08-01T00:00:00Z",
        "sex": "female",
        "createdAt": "2025-08-01T00:00:00Z",
        "updatedAt": "2025-08-01T00:00:00Z"
      }],
      "feedings": [], "sleeps": [], "diapers": [], "vaccinations": [],
      "growth": [], "medications": [], "medicationDoses": [],
      "milkBatches": [], "pediatricContacts": []
    }
    """

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    @Test func versionIsTwo() {
        #expect(DataBackupService.currentVersion == 2)
    }

    @Test func decodesVersionOnePackageWithoutNewFields() throws {
        let package = try makeDecoder().decode(
            DataExportPackage.self, from: Data(v1JSON.utf8)
        )

        #expect(package.version == 1)
        #expect(package.babies.count == 1)
        #expect(package.solidFoods == nil)
        #expect(package.allergenIntroductions == nil)
    }

    @Test func versionOnePackageIsNotRejectedAsIncompatible() throws {
        let package = try makeDecoder().decode(
            DataExportPackage.self, from: Data(v1JSON.utf8)
        )
        // Import yalnız package.version > currentVersion ise reddeder.
        #expect(package.version <= DataBackupService.currentVersion)
    }

    @Test func newExportRoundTripsSolidFoodData() throws {
        let babyID = UUID()
        let package = DataExportPackage(
            version: DataBackupService.currentVersion,
            exportedAt: .now,
            appVersion: "1.5",
            babies: [], feedings: [], sleeps: [], diapers: [],
            vaccinations: [], growth: [], medications: [],
            medicationDoses: [], milkBatches: [], pediatricContacts: [],
            solidFoods: [SolidFoodExport(
                id: UUID(), babyID: babyID, servedAt: .now,
                foodIDs: ["beef", "carrot"], customFoodName: nil,
                method: "puree", amount: "some", reaction: "loved",
                isFirstTry: true, notes: nil, createdAt: .now, updatedAt: .now
            )],
            allergenIntroductions: [AllergenIntroductionExport(
                id: UUID(), babyID: babyID, allergen: "egg",
                status: "tolerated", firstTriedAt: .now, lastServedAt: .now,
                reactionNotes: nil, createdAt: .now, updatedAt: .now
            )]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(package)
        let decoded = try makeDecoder().decode(DataExportPackage.self, from: data)

        #expect(decoded.solidFoods?.count == 1)
        #expect(decoded.solidFoods?.first?.foodIDs == ["beef", "carrot"])
        #expect(decoded.allergenIntroductions?.first?.allergen == "egg")
        #expect(decoded.allergenIntroductions?.first?.status == "tolerated")
    }

    @Test func solidFoodExportRoundTripsThroughModel() {
        let original = SolidFoodExport(
            id: UUID(), babyID: UUID(), servedAt: .now,
            foodIDs: ["yogurt"], customFoodName: "Ev yoğurdu",
            method: "fingerFood", amount: "most", reaction: "adverse",
            isFirstTry: true, notes: "not", createdAt: .now, updatedAt: .now
        )
        let model = original.toModel()
        #expect(model.method == .fingerFood)
        #expect(model.amount == .most)
        #expect(model.reaction == .adverse)
        #expect(model.customFoodName == "Ev yoğurdu")
    }

    @Test func allergenExportRoundTripsThroughModel() {
        let original = AllergenIntroductionExport(
            id: UUID(), babyID: UUID(), allergen: "peanut",
            status: "reacted", firstTriedAt: .now, lastServedAt: nil,
            reactionNotes: "döküntü", createdAt: .now, updatedAt: .now
        )
        let model = original.toModel()
        #expect(model.allergen == .peanut)
        #expect(model.status == .reacted)
        #expect(model.reactionNotes == "döküntü")
    }

    @Test func corruptRawValuesFallBackInsteadOfCrashing() {
        let broken = SolidFoodExport(
            id: UUID(), babyID: UUID(), servedAt: .now,
            foodIDs: [], customFoodName: nil,
            method: "bozuk", amount: "bozuk", reaction: "bozuk",
            isFirstTry: false, notes: nil, createdAt: .now, updatedAt: .now
        )
        let model = broken.toModel()
        #expect(model.method == .puree)
        #expect(model.amount == .some)
        #expect(model.reaction == .neutral)
    }
}
