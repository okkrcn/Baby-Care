import Testing
import Foundation
@testable import Baby_Care

@MainActor
struct TrackingSurfaceSyncTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeBaby(name: String = "Defne", daysOld: Int = 120) -> Baby {
        Baby(name: name, birthDate: now.addingTimeInterval(-Double(daysOld) * 86_400))
    }

    private func minutesAgo(_ minutes: Double) -> Date {
        now.addingTimeInterval(-minutes * 60)
    }

    // MARK: - Widget özeti

    @Test func snapshotPicksLatestCompletedFeedingAndKeepsOngoingSeparate() {
        let baby = makeBaby()
        let bottle = FeedingRecord(babyID: baby.id, type: .bottleFormula,
                                   startedAt: minutesAgo(135), endedAt: minutesAgo(135), amountML: 90)
        let older = FeedingRecord(babyID: baby.id, type: .breast, startedAt: minutesAgo(300),
                                  endedAt: minutesAgo(290), durationSeconds: 600, side: .left)
        let ongoing = FeedingRecord(babyID: baby.id, type: .breast, startedAt: minutesAgo(5), side: .right)

        let snapshot = TrackingSurfaceSync.makeSnapshot(
            baby: baby, feedings: [older, ongoing, bottle], sleeps: [], diapers: [], now: now
        )

        #expect(snapshot.lastFeedingAt == bottle.startedAt)
        #expect(snapshot.lastFeedingDetail == "Mama · 90 ml")
        #expect(snapshot.ongoingFeeding?.recordID == ongoing.id)
        #expect(snapshot.ongoingFeeding?.detail == "Sağ göğüs")
    }

    @Test func snapshotIgnoresOtherBabiesAndFutureRecords() {
        let baby = makeBaby()
        let other = FeedingRecord(babyID: UUID(), type: .bottleFormula,
                                  startedAt: minutesAgo(10), endedAt: minutesAgo(10), amountML: 60)
        let future = DiaperRecord(babyID: baby.id, recordedAt: now.addingTimeInterval(600), type: .poo)
        let otherDiaper = DiaperRecord(babyID: UUID(), recordedAt: minutesAgo(2), type: .pee)

        let snapshot = TrackingSurfaceSync.makeSnapshot(
            baby: baby, feedings: [other], sleeps: [], diapers: [future, otherDiaper], now: now
        )

        #expect(snapshot.lastFeedingAt == nil)
        #expect(snapshot.ongoingFeeding == nil)
        #expect(snapshot.lastDiaperAt == nil)
    }

    @Test func snapshotUsesLatestSleepEndAndOngoingSleep() {
        let baby = makeBaby()
        let night = SleepRecord(babyID: baby.id, startedAt: minutesAgo(600), endedAt: minutesAgo(120), isNap: false)
        let nap = SleepRecord(babyID: baby.id, startedAt: minutesAgo(100), endedAt: minutesAgo(55), isNap: true)
        let ongoing = SleepRecord(babyID: baby.id, startedAt: minutesAgo(3), endedAt: nil, isNap: true)

        let snapshot = TrackingSurfaceSync.makeSnapshot(
            baby: baby, feedings: [], sleeps: [night, ongoing, nap], diapers: [], now: now
        )

        #expect(snapshot.lastSleepEndedAt == nap.endedAt)
        #expect(snapshot.ongoingSleep?.recordID == ongoing.id)
        #expect(snapshot.ongoingSleep?.detail == "Gündüz uykusu")
    }

    @Test func snapshotReportsLatestDiaper() {
        let baby = makeBaby()
        let first = DiaperRecord(babyID: baby.id, recordedAt: minutesAgo(200), type: .pee)
        let last = DiaperRecord(babyID: baby.id, recordedAt: minutesAgo(40), type: .both)

        let snapshot = TrackingSurfaceSync.makeSnapshot(
            baby: baby, feedings: [], sleeps: [], diapers: [last, first], now: now
        )

        #expect(snapshot.lastDiaperAt == last.recordedAt)
        #expect(snapshot.lastDiaperType == "Karışık")
    }

    @Test func breastFeedingDetailIncludesSideAndDuration() {
        let baby = makeBaby()
        let record = FeedingRecord(babyID: baby.id, type: .breast, startedAt: minutesAgo(30),
                                   endedAt: minutesAgo(18), durationSeconds: 720, side: .both)
        #expect(TrackingSurfaceSync.feedingDetail(record) == "Emzirme · İki göğüs · 12 dk")
    }

    @Test func ageTextUsesDaysWeeksMonths() {
        #expect(TrackingSurfaceSync.ageText(for: makeBaby(daysOld: 5), now: now) == "5 günlük")
        #expect(TrackingSurfaceSync.ageText(for: makeBaby(daysOld: 21), now: now) == "3 haftalık")
        #expect(TrackingSurfaceSync.ageText(for: makeBaby(daysOld: 125), now: now) == "4 aylık")
    }

    // MARK: - Live Activity eşleme

    @Test func desiredActivitiesCoverOngoingTimersOfAllBabies() {
        let defne = makeBaby(name: "Defne")
        let ada = makeBaby(name: "Ada")
        let feeding = FeedingRecord(babyID: defne.id, type: .breast, startedAt: minutesAgo(12), side: .left)
        let sleep = SleepRecord(babyID: ada.id, startedAt: minutesAgo(30), endedAt: nil, isNap: false)
        let bottle = FeedingRecord(babyID: defne.id, type: .bottleFormula,
                                   startedAt: minutesAgo(1), endedAt: nil, amountML: 60)

        let desired = TrackingSurfaceSync.desiredActivities(
            babies: [defne, ada], ongoingFeedings: [feeding, bottle], ongoingSleeps: [sleep]
        )

        #expect(desired.count == 2)
        #expect(desired[0].recordID == sleep.id)
        #expect(desired[0].babyName == "Ada")
        #expect(desired[0].isFeeding == false)
        #expect(desired[0].detail == "Gece uykusu")
        #expect(desired[1].recordID == feeding.id)
        #expect(desired[1].detail == "Sol göğüs")
    }

    @Test func desiredActivitiesSkipOrphanRecords() {
        let orphan = SleepRecord(babyID: UUID(), startedAt: minutesAgo(10), endedAt: nil)
        let desired = TrackingSurfaceSync.desiredActivities(babies: [], ongoingFeedings: [], ongoingSleeps: [orphan])
        #expect(desired.isEmpty)
    }

    // MARK: - App Group deposu

    @Test func storeRoundTripsAndReportsChanges() throws {
        let suite = "TrackingSurfaceSyncTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let baby = makeBaby()
        let snapshot = TrackingSurfaceSync.makeSnapshot(baby: baby, feedings: [], sleeps: [], diapers: [], now: now)

        #expect(WidgetSnapshotStore.save(snapshot, to: defaults))
        #expect(WidgetSnapshotStore.load(from: defaults) == snapshot)

        var regenerated = snapshot
        regenerated.generatedAt = now.addingTimeInterval(60)
        #expect(WidgetSnapshotStore.save(regenerated, to: defaults) == false)

        #expect(WidgetSnapshotStore.save(nil, to: defaults))
        #expect(WidgetSnapshotStore.load(from: defaults) == nil)
    }
}
