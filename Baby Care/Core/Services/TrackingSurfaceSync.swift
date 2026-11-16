import Foundation
import OSLog
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif
#if os(iOS)
import ActivityKit
import UIKit
#endif

/// Veritabanındaki takip durumunu uygulama dışı yüzeylere yansıtır:
/// ana ekran / kilit ekranı widget'ları ve emzirme-uyku Live Activity'leri.
///
/// Her `ModelContext.didSave` sonrasında çalışır; böylece kayıt hangi ekrandan,
/// Siri'den veya widget düğmesinden gelirse gelsin yüzeyler aynı kalır.
@MainActor
enum TrackingSurfaceSync {
    private static let logger = Logger(subsystem: "okkrcn.Baby-Care", category: "TrackingSurfaceSync")
    private static var container: ModelContainer?
    private static var observers: [NSObjectProtocol] = []

    /// Uygulama açılışında bir kez çağrılır.
    static func start(container: ModelContainer) {
        guard self.container == nil else { return }
        self.container = container

        observers.append(NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: nil, queue: .main
        ) { note in
            let inserted = (note.userInfo?[ModelContext.NotificationKey.insertedIdentifiers.rawValue]
                as? [PersistentIdentifier]) ?? []
            let names = inserted.map(\.entityName)
            MainActor.assumeIsolated {
                refresh()
                // Puan isteme sayacı: hangi ekrandan veya widget'tan gelirse gelsin
                // başarılı bir bakım kaydı tek etkileşim sayılır.
                if ReviewRequester.isInteraction(insertedEntityNames: names) {
                    ReviewRequester.registerInteraction()
                }
            }
        })

        #if os(iOS)
        observers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { refresh() }
        })
        #endif

        Task { @MainActor in refresh() }
    }

    /// Widget özetini yeniden yazar ve Live Activity'leri kayıtlarla eşler.
    static func refresh() {
        guard let container else { return }
        let context = container.mainContext
        do {
            let babies = try context.fetch(FetchDescriptor<Baby>(sortBy: [SortDescriptor(\.createdAt)]))
            let ongoingFeedings = try context.fetch(FetchDescriptor<FeedingRecord>(
                predicate: #Predicate { $0.endedAt == nil }
            )).filter(\.isOngoing)
            let ongoingSleeps = try context.fetch(FetchDescriptor<SleepRecord>(
                predicate: #Predicate { $0.endedAt == nil }
            ))

            updateWidgets(babies: babies, ongoingFeedings: ongoingFeedings,
                          ongoingSleeps: ongoingSleeps, in: context)

            #if os(iOS)
            reconcileActivities(desiredActivities(
                babies: babies, ongoingFeedings: ongoingFeedings, ongoingSleeps: ongoingSleeps
            ))
            #endif
        } catch {
            logger.error("Takip yüzeyleri güncellenemedi: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Widget özeti

    private static func updateWidgets(
        babies: [Baby],
        ongoingFeedings: [FeedingRecord],
        ongoingSleeps: [SleepRecord],
        in context: ModelContext
    ) {
        let snapshot: WidgetSnapshot?
        if let baby = selectedBaby(in: babies) {
            let babyID = baby.id
            var recentFeedings = FetchDescriptor<FeedingRecord>(
                predicate: #Predicate { $0.babyID == babyID },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            recentFeedings.fetchLimit = 30
            var recentSleeps = FetchDescriptor<SleepRecord>(
                predicate: #Predicate { $0.babyID == babyID },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            recentSleeps.fetchLimit = 30
            var recentDiapers = FetchDescriptor<DiaperRecord>(
                predicate: #Predicate { $0.babyID == babyID },
                sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
            )
            recentDiapers.fetchLimit = 5

            let feedings = ((try? context.fetch(recentFeedings)) ?? []) + ongoingFeedings
            let sleeps = ((try? context.fetch(recentSleeps)) ?? []) + ongoingSleeps
            let diapers = (try? context.fetch(recentDiapers)) ?? []
            snapshot = makeSnapshot(baby: baby, feedings: feedings, sleeps: sleeps,
                                    diapers: diapers, now: .now)
        } else {
            snapshot = nil
        }

        if WidgetSnapshotStore.save(snapshot) {
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    private static func selectedBaby(in babies: [Baby]) -> Baby? {
        if let raw = UserDefaults.standard.string(forKey: "selectedBabyID"),
           let id = UUID(uuidString: raw),
           let match = babies.first(where: { $0.id == id }) {
            return match
        }
        return babies.first
    }

    /// Kayıtlardan widget özetini üretir. Başka bebeğe ait kayıtlar yok sayılır.
    static func makeSnapshot(
        baby: Baby,
        feedings: [FeedingRecord],
        sleeps: [SleepRecord],
        diapers: [DiaperRecord],
        now: Date
    ) -> WidgetSnapshot {
        let feedings = feedings.filter { $0.babyID == baby.id }
        let sleeps = sleeps.filter { $0.babyID == baby.id }
        let diapers = diapers.filter { $0.babyID == baby.id && $0.recordedAt <= now }

        let ongoingFeeding = feedings.filter(\.isOngoing).max { $0.startedAt < $1.startedAt }
        let lastFeeding = feedings
            .filter { !$0.isOngoing && $0.startedAt <= now }
            .max { $0.startedAt < $1.startedAt }

        let ongoingSleep = sleeps.filter(\.isOngoing).max { $0.startedAt < $1.startedAt }
        let lastSleepEnd = sleeps.compactMap(\.endedAt).filter { $0 <= now }.max()

        let lastDiaper = diapers.max { $0.recordedAt < $1.recordedAt }

        return WidgetSnapshot(
            babyName: baby.name,
            ageText: ageText(for: baby, now: now),
            lastFeedingAt: lastFeeding?.startedAt,
            lastFeedingDetail: lastFeeding.map(feedingDetail),
            ongoingFeeding: ongoingFeeding.map {
                .init(recordID: $0.id, startedAt: $0.startedAt, detail: sideDetail($0.side))
            },
            lastSleepEndedAt: lastSleepEnd,
            ongoingSleep: ongoingSleep.map {
                .init(recordID: $0.id, startedAt: $0.startedAt, detail: sleepDetail($0))
            },
            lastDiaperAt: lastDiaper?.recordedAt,
            lastDiaperType: lastDiaper?.type.localizedTitle,
            generatedAt: now
        )
    }

    static func ageText(for baby: Baby, now: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: baby.birthDate, to: now).day ?? 0
        let months = calendar.dateComponents([.month], from: baby.birthDate, to: now).month ?? 0
        if days < 14 { return "\(max(0, days)) günlük" }
        if months < 1 { return "\(days / 7) haftalık" }
        if months < 24 { return "\(months) aylık" }
        return "\(months / 12) yaşında"
    }

    static func feedingDetail(_ record: FeedingRecord) -> String {
        switch record.type {
        case .breast:
            var parts = ["Emzirme"]
            if let side = record.side { parts.append(side == .both ? "İki göğüs" : side.localizedTitle) }
            if let seconds = record.durationSeconds { parts.append(DurationFormatter.string(fromSeconds: seconds)) }
            return parts.joined(separator: " · ")
        case .bottleBreastmilk:
            return record.amountML.map { "Sağılmış süt · \($0) ml" } ?? "Sağılmış süt"
        case .bottleFormula:
            return record.amountML.map { "Mama · \($0) ml" } ?? "Mama"
        }
    }

    static func sideDetail(_ side: BreastSide?) -> String {
        switch side {
        case .left: return "Sol göğüs"
        case .right: return "Sağ göğüs"
        case .both: return "İki göğüs"
        case nil: return "Emzirme"
        }
    }

    static func sleepDetail(_ record: SleepRecord) -> String {
        record.isNap ? "Gündüz uykusu" : "Gece uykusu"
    }

    // MARK: - Live Activity

    struct DesiredActivity: Equatable {
        var recordID: UUID
        var isFeeding: Bool
        var babyName: String
        var startedAt: Date
        var detail: String
    }

    /// Devam eden her emzirme ve uyku için bir aktivite (ikizler dahil).
    /// Bebeği silinmiş sahipsiz kayıtlar için aktivite açılmaz.
    static func desiredActivities(
        babies: [Baby],
        ongoingFeedings: [FeedingRecord],
        ongoingSleeps: [SleepRecord]
    ) -> [DesiredActivity] {
        let names = Dictionary(babies.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let feedings: [DesiredActivity] = ongoingFeedings.filter(\.isOngoing).compactMap { record in
            guard let name = names[record.babyID] else { return nil }
            return DesiredActivity(recordID: record.id, isFeeding: true, babyName: name,
                                   startedAt: record.startedAt, detail: sideDetail(record.side))
        }
        let sleeps: [DesiredActivity] = ongoingSleeps.filter(\.isOngoing).compactMap { record in
            guard let name = names[record.babyID] else { return nil }
            return DesiredActivity(recordID: record.id, isFeeding: false, babyName: name,
                                   startedAt: record.startedAt, detail: sleepDetail(record))
        }
        return (feedings + sleeps).sorted { $0.startedAt < $1.startedAt }
    }

    #if os(iOS)
    /// Bir kayıt için aktivite yalnız bir kez açılır. Kullanıcı aktiviteyi
    /// kilit ekranından kaldırırsa aynı kayıt için geri getirilmez.
    /// Uygulama güncellemesi açık aktiviteleri kapatır; sürüm değişince liste
    /// sıfırlanır ki devam eden sayaçlar yeniden açılabilsin.
    private static let startedKey = "liveActivityStartedRecordIDs"
    private static let startedBuildKey = "liveActivityStartedBuild"

    private static func reconcileActivities(_ desired: [DesiredActivity]) {
        let existing = Activity<TrackingActivityAttributes>.activities
        let desiredIDs = Set(desired.map(\.recordID))

        for activity in existing where !desiredIDs.contains(activity.attributes.recordID) {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        let defaults = UserDefaults.standard
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        if defaults.string(forKey: startedBuildKey) != build {
            defaults.removeObject(forKey: startedKey)
            defaults.set(build, forKey: startedBuildKey)
        }
        var started = Set((defaults.stringArray(forKey: startedKey) ?? [])
            .compactMap(UUID.init(uuidString:)))
        // Artık devam etmeyen kayıtları unut ki liste büyümesin.
        started.formIntersection(desiredIDs)

        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        for item in desired {
            let state = TrackingActivityAttributes.ContentState(startedAt: item.startedAt, detail: item.detail)
            if let match = existing.first(where: { $0.attributes.recordID == item.recordID }) {
                started.insert(item.recordID)
                if match.activityState == .active, match.content.state != state {
                    Task { await match.update(ActivityContent(state: state, staleDate: nil)) }
                }
                continue
            }
            guard enabled, !started.contains(item.recordID) else { continue }
            let attributes = TrackingActivityAttributes(
                kind: item.isFeeding ? .feeding : .sleep,
                recordID: item.recordID,
                babyName: item.babyName
            )
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                started.insert(item.recordID)
            } catch {
                // Uygulama arka plandayken (ör. Siri) başlatılamayabilir; bir sonraki
                // ön plana gelişte yeniden denenir.
                logger.info("Live Activity başlatılamadı: \(error.localizedDescription, privacy: .public)")
            }
        }

        defaults.set(started.map(\.uuidString), forKey: startedKey)
    }
    #endif
}
