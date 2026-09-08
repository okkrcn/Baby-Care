import Testing
@testable import Baby_Care

struct FeedingCalculatorTests {

    @Test func firstWeekUsesAscendingPerKgValues() {
        let day1 = FeedingCalculator.calculate(ageDays: 0, weightKg: 3.2)
        #expect(day1.mlPerKgMin == 60)
        let day3 = FeedingCalculator.calculate(ageDays: 2, weightKg: 3.2)
        #expect(day3.mlPerKgMin == 100)
    }

    @Test func infantUnderSixMonthsUsesFullMilkRange() {
        let threeMonths = FeedingCalculator.calculate(ageDays: 90, weightKg: 6.0)
        #expect(threeMonths.mlPerKgMin == 150)
        #expect(threeMonths.mlPerKgMax == 180)
        #expect(threeMonths.stage == .newborn)
        #expect(threeMonths.solidFoodKcal == nil)
    }

    @Test func complementaryStageReducesMilkTarget() {
        // 8 aylık: süt ana besin olmayı sürdürür ama ek gıda enerjinin bir
        // kısmını karşılar; ml/kg hedefi düşer.
        let eightMonths = FeedingCalculator.calculate(ageDays: 240, weightKg: 8.5)
        #expect(eightMonths.stage == .complementary)
        #expect(eightMonths.mlPerKgMax < 150)
        #expect(eightMonths.dailyMaxML < FeedingCalculator
            .calculate(ageDays: 90, weightKg: 8.5).dailyMaxML)
    }

    @Test func complementaryStageReportsSolidFoodEnergy() {
        // TÜBER 2022: 6-8 ay ~200 kcal, 9-11 ay ~300 kcal, 12-24 ay ~550 kcal
        #expect(FeedingCalculator.calculate(ageDays: 210, weightKg: 8.0).solidFoodKcal == 200)
        #expect(FeedingCalculator.calculate(ageDays: 300, weightKg: 9.0).solidFoodKcal == 300)
        #expect(FeedingCalculator.calculate(ageDays: 450, weightKg: 10.5).solidFoodKcal == 550)
    }

    @Test func toddlerStageIsDetected() {
        let eighteenMonths = FeedingCalculator.calculate(ageDays: 548, weightKg: 11.0)
        #expect(eighteenMonths.stage == .toddler)
        #expect(eighteenMonths.solidFoodKcal == 550)
    }

    @Test func milkNoteIsNeverEmpty() {
        for days in [0, 30, 90, 200, 300, 400, 700] {
            let result = FeedingCalculator.calculate(ageDays: days, weightKg: 7.0)
            #expect(!result.milkNote.isEmpty, "gün \(days): not boş")
        }
    }

    @Test func typicalFeedingsDecreaseWithAge() {
        let newborn = FeedingCalculator.calculate(ageDays: 10, weightKg: 3.5)
        let sixMonths = FeedingCalculator.calculate(ageDays: 190, weightKg: 7.8)
        #expect(newborn.typicalFeedingsPerDay > sixMonths.typicalFeedingsPerDay)
    }

    @Test func weightIsClampedToMinimum() {
        let result = FeedingCalculator.calculate(ageDays: 30, weightKg: 0.1)
        #expect(result.weightKg == 0.5)
    }
}
