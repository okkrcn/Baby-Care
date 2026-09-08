import Testing
import Foundation
import SwiftData
@testable import Baby_Care

@MainActor
struct SolidFoodServiceTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Baby.self, SolidFoodRecord.self, AllergenIntroduction.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private func makeBaby(in context: ModelContext, name: String = "Test") -> Baby {
        let eightMonthsAgo = Calendar.current.date(byAdding: .month, value: -8, to: .now)!
        let baby = Baby(name: name, birthDate: eightMonthsAgo)
        context.insert(baby)
        return baby
    }

    @Test func logCreatesRecord() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        let record = try SolidFoodService.log(
            foodIDs: ["beef"], method: .puree, amount: .some,
            reaction: .loved, for: baby, in: context
        )

        #expect(record.foodIDs == ["beef"])
        #expect(try context.fetch(FetchDescriptor<SolidFoodRecord>()).count == 1)
    }

    @Test func firstTryIsMarkedOnFirstServingOnly() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        let first = try SolidFoodService.log(
            foodIDs: ["carrot"], method: .puree, amount: .some,
            reaction: .loved, for: baby, in: context
        )
        let second = try SolidFoodService.log(
            foodIDs: ["carrot"], method: .puree, amount: .all,
            reaction: .loved, for: baby, in: context
        )

        #expect(first.isFirstTry == true)
        #expect(second.isFirstTry == false)
    }

    @Test func firstTryIsMarkedWhenAnyFoodIsNew() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["carrot"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)
        // Havuç bilinen, elma yeni → kayıt "yeni besin" sayılır
        let mixed = try SolidFoodService.log(foodIDs: ["carrot", "apple"], method: .puree,
                                             amount: .some, reaction: .loved,
                                             for: baby, in: context)
        #expect(mixed.isFirstTry == true)
    }

    @Test func loggingAllergenFoodCreatesIntroductionRecord() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(
            foodIDs: ["yogurt"], method: .puree, amount: .some,
            reaction: .loved, for: baby, in: context
        )

        let intros = SolidFoodService.introductions(for: baby.id, in: context)
        let milk = intros.first { $0.allergen == .milk }
        #expect(milk?.status == .introduced)
        #expect(milk?.firstTriedAt != nil)
        #expect(milk?.lastServedAt != nil)
    }

    @Test func secondSuccessfulServingMarksTolerated() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)
        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .all, reaction: .neutral,
                                     for: baby, in: context)

        let milk = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .milk }
        #expect(milk?.status == .tolerated)
    }

    @Test func adverseReactionMarksReacted() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["egg"], method: .puree,
                                     amount: .tasted, reaction: .adverse,
                                     for: baby, in: context)

        let egg = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .egg }
        #expect(egg?.status == .reacted)
    }

    @Test func reactedStatusIsNotOverwrittenByLaterServing() throws {
        // Tepki gözlenmiş alerjen sonraki kayıtla "sorunsuz"a dönmez;
        // durum değişikliği hekim değerlendirmesine bağlıdır.
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["egg"], method: .puree,
                                     amount: .tasted, reaction: .adverse,
                                     for: baby, in: context)
        _ = try SolidFoodService.log(foodIDs: ["egg"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)

        let egg = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .egg }
        #expect(egg?.status == .reacted)
    }

    @Test func refusedServingDoesNotAdvanceStatus() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .tasted, reaction: .refused,
                                     for: baby, in: context)

        let milk = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .milk }
        #expect(milk?.status == .notIntroduced)
    }

    @Test func multipleAllergensInOneMealAllAdvance() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        // Yumurta + tahin: iki farklı alerjen aynı öğünde
        _ = try SolidFoodService.log(foodIDs: ["egg", "tahini"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)

        let intros = SolidFoodService.introductions(for: baby.id, in: context)
        #expect(intros.first { $0.allergen == .egg }?.status == .introduced)
        #expect(intros.first { $0.allergen == .sesame }?.status == .introduced)
    }

    @Test func introductionsCoverAllNineAllergens() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        let intros = SolidFoodService.introductions(for: baby.id, in: context)
        #expect(intros.count == 9)
        #expect(Set(intros.map(\.allergen)) == Set(Allergen.allCases))
    }

    @Test func introductionsAreNotDuplicatedAcrossCalls() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = SolidFoodService.introductions(for: baby.id, in: context)
        _ = SolidFoodService.introductions(for: baby.id, in: context)

        #expect(try context.fetch(FetchDescriptor<AllergenIntroduction>()).count == 9)
    }

    @Test func introductionsAreScopedPerBaby() throws {
        let context = try makeContext()
        let first = makeBaby(in: context, name: "Bir")
        let second = makeBaby(in: context, name: "İki")

        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: first, in: context)
        let secondMilk = SolidFoodService.introductions(for: second.id, in: context)
            .first { $0.allergen == .milk }
        #expect(secondMilk?.status == .notIntroduced)
    }

    @Test func nonAllergenFoodCreatesNoIntroductionSideEffect() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        // Havuç alerjen değil — hiçbir alerjen kaydı ilerlemer
        _ = try SolidFoodService.log(foodIDs: ["carrot"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)

        let intros = SolidFoodService.introductions(for: baby.id, in: context)
        #expect(intros.allSatisfy { $0.status == .notIntroduced })
    }
}
