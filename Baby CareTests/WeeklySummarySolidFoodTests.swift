import Testing
import Foundation
@testable import Baby_Care

@MainActor
struct WeeklySummarySolidFoodTests {

    private func makeBaby(months: Int = 9) -> Baby {
        Baby(name: "Test",
             birthDate: Calendar.current.date(byAdding: .month, value: -months, to: .now)!)
    }

    @Test func countsSolidFoodMealsWithinTheWeek() {
        let baby = makeBaby()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: .now)!

        let solids = [
            SolidFoodRecord(babyID: baby.id, servedAt: twoDaysAgo,
                            foodIDs: ["carrot"], isFirstTry: true),
            SolidFoodRecord(babyID: baby.id, servedAt: twoDaysAgo,
                            foodIDs: ["apple"], isFirstTry: false),
            SolidFoodRecord(babyID: baby.id, servedAt: tenDaysAgo,
                            foodIDs: ["pear"], isFirstTry: true)
        ]

        let summary = WeeklySummaryCalculator.calculate(
            for: baby, feedings: [], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: solids
        )

        #expect(summary.solidFoodMeals == 2)
        #expect(summary.newFoodsTried == 1)
    }

    @Test func excludesOtherBabiesRecords() {
        let baby = makeBaby()
        let solids = [SolidFoodRecord(babyID: UUID(), foodIDs: ["carrot"])]

        let summary = WeeklySummaryCalculator.calculate(
            for: baby, feedings: [], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: solids
        )

        #expect(summary.solidFoodMeals == 0)
    }

    @Test func emptySolidFoodListYieldsZero() {
        let summary = WeeklySummaryCalculator.calculate(
            for: makeBaby(months: 1), feedings: [], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: []
        )
        #expect(summary.solidFoodMeals == 0)
        #expect(summary.newFoodsTried == 0)
    }

    @Test func existingSummaryFieldsAreUnaffected() {
        // Yeni parametre mevcut hesapları bozmamalı.
        let baby = makeBaby()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let feeding = FeedingRecord(babyID: baby.id, type: .bottleFormula,
                                    startedAt: yesterday, amountML: 120)

        let summary = WeeklySummaryCalculator.calculate(
            for: baby, feedings: [feeding], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: []
        )

        #expect(summary.totalFeedings == 1)
        #expect(summary.totalBottleML == 120)
    }
}
