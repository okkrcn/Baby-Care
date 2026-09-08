import Testing
import Foundation
@testable import Baby_Care

struct BabyStageTests {

    @Test func newbornUnderSixMonths() {
        #expect(BabyStage.forAgeMonths(0) == .newborn)
        #expect(BabyStage.forAgeMonths(5) == .newborn)
    }

    @Test func complementaryFromSixToTwelveMonths() {
        #expect(BabyStage.forAgeMonths(6) == .complementary)
        #expect(BabyStage.forAgeMonths(11) == .complementary)
    }

    @Test func toddlerFromTwelveMonths() {
        #expect(BabyStage.forAgeMonths(12) == .toddler)
        #expect(BabyStage.forAgeMonths(24) == .toddler)
        #expect(BabyStage.forAgeMonths(36) == .toddler)
    }

    @Test func solidFoodAgeStartsAtSixMonths() {
        #expect(BabyStage.forAgeMonths(5).isSolidFoodAge == false)
        #expect(BabyStage.forAgeMonths(6).isSolidFoodAge == true)
        #expect(BabyStage.forAgeMonths(20).isSolidFoodAge == true)
    }

    @Test func babyExposesStageFromBirthDate() {
        let eightMonthsAgo = Calendar.current.date(byAdding: .month, value: -8, to: .now)!
        let baby = Baby(name: "Test", birthDate: eightMonthsAgo)
        #expect(baby.stage == .complementary)
    }

    @Test func negativeAgeIsTreatedAsNewborn() {
        #expect(BabyStage.forAgeMonths(-1) == .newborn)
    }
}
