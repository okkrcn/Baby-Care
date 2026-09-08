import Testing
import Foundation
@testable import Baby_Care

struct SolidFoodSummaryTests {

    @Test func emptyDayShowsDash() {
        let summary = SolidFoodDaySummary.make(from: [])
        #expect(summary.mealCount == 0)
        #expect(summary.detailText == "—")
    }

    @Test func countsMealsAndFirstTries() {
        let babyID = UUID()
        let records = [
            SolidFoodRecord(babyID: babyID, foodIDs: ["carrot"], isFirstTry: true),
            SolidFoodRecord(babyID: babyID, foodIDs: ["apple"], isFirstTry: false),
            SolidFoodRecord(babyID: babyID, foodIDs: ["beef"], isFirstTry: true)
        ]
        let summary = SolidFoodDaySummary.make(from: records)
        #expect(summary.mealCount == 3)
        #expect(summary.firstTryCount == 2)
        #expect(summary.detailText == "2 yeni besin")
    }

    @Test func singleFirstTryStillReadsNaturally() {
        let records = [SolidFoodRecord(babyID: UUID(), foodIDs: ["pear"], isFirstTry: true)]
        #expect(SolidFoodDaySummary.make(from: records).detailText == "1 yeni besin")
    }

    @Test func noFirstTryShowsExplicitPhrase() {
        let records = [SolidFoodRecord(babyID: UUID(), foodIDs: ["pear"], isFirstTry: false)]
        #expect(SolidFoodDaySummary.make(from: records).detailText == "yeni besin yok")
    }
}
