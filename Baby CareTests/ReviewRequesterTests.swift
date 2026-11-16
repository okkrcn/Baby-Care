import Testing
import Foundation
@testable import Baby_Care

@MainActor
struct ReviewRequesterTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func careRecordsCountAsInteraction() {
        for name in ["FeedingRecord", "SleepRecord", "DiaperRecord", "ToothEruption", "SolidFoodRecord"] {
            #expect(ReviewRequester.isInteraction(insertedEntityNames: [name]), "\(name)")
        }
    }

    @Test func generatedOrProfileRecordsDoNotCount() {
        // Onboarding'de aşı takvimi toplu üretilir; bebek profili kayıt değildir.
        #expect(!ReviewRequester.isInteraction(insertedEntityNames: ["VaccinationRecord", "Baby"]))
        #expect(!ReviewRequester.isInteraction(insertedEntityNames: []))
    }

    @Test func mixedSaveCountsOnce() {
        #expect(ReviewRequester.isInteraction(insertedEntityNames: ["VaccinationRecord", "DiaperRecord"]))
    }

    @Test func waitsForThreshold() {
        #expect(!ReviewRequester.shouldRequest(count: 6, lastRequest: nil, now: now))
        #expect(ReviewRequester.shouldRequest(count: 7, lastRequest: nil, now: now))
    }

    @Test func respectsThirtyDayGap() {
        let tenDaysAgo = now.addingTimeInterval(-10 * 86_400)
        let fortyDaysAgo = now.addingTimeInterval(-40 * 86_400)
        #expect(!ReviewRequester.shouldRequest(count: 50, lastRequest: tenDaysAgo, now: now))
        #expect(ReviewRequester.shouldRequest(count: 50, lastRequest: fortyDaysAgo, now: now))
    }
}
