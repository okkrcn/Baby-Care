import Testing
import Foundation
import SwiftData
@testable import Baby_Care

@MainActor
struct SolidFoodModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            Baby.self, FeedingRecord.self, SleepRecord.self, DiaperRecord.self,
            VaccinationRecord.self, GrowthRecord.self, Medication.self,
            MedicationDose.self, PediatricContact.self, BreastMilkBatch.self,
            SolidFoodRecord.self, AllergenIntroduction.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @Test func persistsSolidFoodRecord() throws {
        let context = try makeContext()
        let babyID = UUID()
        let record = SolidFoodRecord(
            babyID: babyID,
            foodIDs: ["beef", "carrot"],
            method: .puree,
            amount: .some,
            reaction: .loved,
            isFirstTry: true
        )
        context.insert(record)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SolidFoodRecord>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.foodIDs == ["beef", "carrot"])
        #expect(fetched.first?.method == .puree)
        #expect(fetched.first?.amount == .some)
        #expect(fetched.first?.reaction == .loved)
        #expect(fetched.first?.isFirstTry == true)
    }

    @Test func enumAccessorsRoundTripThroughRawValues() {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: [])
        record.method = .familyMeal
        record.amount = .all
        record.reaction = .adverse
        #expect(record.methodRaw == "familyMeal")
        #expect(record.amountRaw == "all")
        #expect(record.reactionRaw == "adverse")
        #expect(record.method == .familyMeal)
        #expect(record.reaction == .adverse)
    }

    @Test func unknownRawValueFallsBackSafely() {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: [])
        record.methodRaw = "bilinmeyen"
        record.reactionRaw = "bozuk"
        #expect(record.method == .puree)
        #expect(record.reaction == .neutral)
    }

    @Test func displayNameResolvesCatalogFoods() {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: ["beef", "carrot"])
        #expect(record.displayName == "Kırmızı et (dana), Havuç (pişmiş)")
    }

    @Test func displayNameIncludesCustomFood() {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: ["banana"],
                                     customFoodName: "Ev yapımı kek")
        #expect(record.displayName.contains("Muz"))
        #expect(record.displayName.contains("Ev yapımı kek"))
    }

    @Test func displayNameFallsBackWhenEmpty() {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: [])
        #expect(record.displayName == "Besin belirtilmedi")
    }

    @Test func unknownFoodIDsAreSkippedInFoods() {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: ["banana", "olmayan_besin"])
        #expect(record.foods.count == 1)
        #expect(record.foods.first?.id == "banana")
    }

    @Test func persistsAllergenIntroduction() throws {
        let context = try makeContext()
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .peanut)
        context.insert(intro)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AllergenIntroduction>())
        #expect(fetched.first?.allergen == .peanut)
        #expect(fetched.first?.status == .notIntroduced)
        #expect(fetched.first?.firstTriedAt == nil)
    }

    @Test func daysSinceLastServedIsNilWhenNeverServed() {
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .egg)
        #expect(intro.daysSinceLastServed == nil)
    }

    @Test func daysSinceLastServedCountsFromLastServing() {
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .egg)
        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -10, to: .now)
        #expect(intro.daysSinceLastServed == 10)
    }

    @Test func needsReminderWhenToleratedFoodNotServedForTwoWeeks() {
        // AAP 2023: tolere edilen alerjen diyette düzenli tutulmalı.
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .egg)
        intro.status = .tolerated
        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -15, to: .now)
        #expect(intro.needsRegularityReminder == true)

        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -3, to: .now)
        #expect(intro.needsRegularityReminder == false)
    }

    @Test func reactedAllergenNeverAsksForRegularity() {
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .peanut)
        intro.status = .reacted
        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -60, to: .now)
        #expect(intro.needsRegularityReminder == false)
    }

    @Test func babyDeleteRemovesSolidFoodData() async throws {
        let context = try makeContext()
        let baby = Baby(name: "Test", birthDate: .now)
        context.insert(baby)
        context.insert(SolidFoodRecord(babyID: baby.id, foodIDs: ["apple"]))
        context.insert(AllergenIntroduction(babyID: baby.id, allergen: .milk))
        try context.save()

        await BabyDeleteService.delete(baby, from: context)

        #expect(try context.fetch(FetchDescriptor<SolidFoodRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<AllergenIntroduction>()).isEmpty)
    }

    @Test func babyDeleteLeavesOtherBabiesDataIntact() async throws {
        let context = try makeContext()
        let first = Baby(name: "Bir", birthDate: .now)
        let second = Baby(name: "İki", birthDate: .now)
        context.insert(first)
        context.insert(second)
        context.insert(SolidFoodRecord(babyID: first.id, foodIDs: ["apple"]))
        context.insert(SolidFoodRecord(babyID: second.id, foodIDs: ["pear"]))
        try context.save()

        await BabyDeleteService.delete(first, from: context)

        let remaining = try context.fetch(FetchDescriptor<SolidFoodRecord>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.babyID == second.id)
    }
}
