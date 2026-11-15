#if os(iOS)
import AppIntents
import Foundation
import SwiftData

/// Widget ve Live Activity düğmelerinin uygulama tarafı.
/// `Shared/TrackingWidgetIntents.swift` içindeki intent'ler sistem tarafından
/// uygulama sürecinde çalıştırılır ve buraya devreder.
@MainActor
enum WidgetActionPerformer {
    private static var context: ModelContext { QuickIntentSupport.modelContext }

    static func toggleFeeding() throws {
        let baby = try QuickIntentSupport.resolveTargetBaby()
        try QuickLogService.toggleFeeding(for: baby, ongoing: try ongoingFeeding(for: baby.id), in: context)
        TrackingSurfaceSync.refresh()
    }

    static func toggleSleep() throws {
        let baby = try QuickIntentSupport.resolveTargetBaby()
        try QuickLogService.toggleSleep(for: baby, ongoing: try ongoingSleep(for: baby.id), in: context)
        TrackingSurfaceSync.refresh()
    }

    static func logDiaper(_ kind: WidgetDiaperKind) throws {
        let baby = try QuickIntentSupport.resolveTargetBaby()
        try QuickLogService.logDiaper(kind == .pee ? .pee : .poo, for: baby, in: context)
        TrackingSurfaceSync.refresh()
    }

    /// Live Activity'deki kaydı bitirir. Kayıt zaten bitmişse yalnız yüzeyleri eşler.
    static func endTimer(recordID: UUID, kind: WidgetTimerKind) throws {
        switch kind {
        case .feeding:
            let descriptor = FetchDescriptor<FeedingRecord>(predicate: #Predicate { $0.id == recordID })
            if let record = try context.fetch(descriptor).first, record.isOngoing {
                try QuickLogService.endFeeding(record, in: context)
            }
        case .sleep:
            let descriptor = FetchDescriptor<SleepRecord>(predicate: #Predicate { $0.id == recordID })
            if let record = try context.fetch(descriptor).first, record.isOngoing {
                try QuickLogService.endSleep(record, in: context)
            }
        }
        TrackingSurfaceSync.refresh()
    }

    private static func ongoingFeeding(for babyID: UUID) throws -> FeedingRecord? {
        let descriptor = FetchDescriptor<FeedingRecord>(
            predicate: #Predicate { $0.babyID == babyID && $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first(where: \.isOngoing)
    }

    private static func ongoingSleep(for babyID: UUID) throws -> SleepRecord? {
        let descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.babyID == babyID && $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first
    }
}

// Siri ve Kestirmeler'den başlatılan sayaçlar da Live Activity açabilsin diye
// mevcut intent'ler uygulama sürecinde çalışan LiveActivityIntent olarak işaretlenir.
extension StartSleepIntent: LiveActivityIntent {}
extension StartFeedingIntent: LiveActivityIntent {}
#endif
