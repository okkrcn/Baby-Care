import Foundation
import AppIntents
import SwiftData

/// AppIntents tabanlı hızlı kayıt yardımcısı.
/// Home Screen icon → uzun bas → menü ya da Siri'den tetiklenir.
@MainActor
enum QuickIntentSupport {
    static var modelContext: ModelContext {
        Baby_CareApp.sharedModelContainer.mainContext
    }

    /// Seçili bebeği döner (UserDefaults'tan) ya da ilk bebeği.
    static func resolveTargetBaby() throws -> Baby {
        let context = modelContext

        if let raw = UserDefaults.standard.string(forKey: "selectedBabyID"),
           let id = UUID(uuidString: raw) {
            let descriptor = FetchDescriptor<Baby>(predicate: #Predicate { $0.id == id })
            if let match = try context.fetch(descriptor).first {
                return match
            }
        }

        let fallback = FetchDescriptor<Baby>(sortBy: [SortDescriptor(\.createdAt)])
        guard let baby = try context.fetch(fallback).first else {
            throw QuickIntentError.noBaby
        }
        return baby
    }

    enum QuickIntentError: LocalizedError {
        case noBaby

        var errorDescription: String? {
            switch self {
            case .noBaby:
                return "Henüz bebek profili eklenmedi. Uygulamayı açıp bilgilerini girin."
            }
        }
    }
}

// MARK: - Sleep

struct StartSleepIntent: AppIntent {
    static let title: LocalizedStringResource = "Uyku Başlat"
    static let description = IntentDescription("Bebeğiniz için yeni bir uyku kaydı başlatır.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let baby = try QuickIntentSupport.resolveTargetBaby()
        let hour = Calendar.current.component(.hour, from: .now)
        let isNap = hour >= 7 && hour < 19

        let record = SleepRecord(
            babyID: baby.id,
            startedAt: .now,
            endedAt: nil,
            isNap: isNap
        )
        QuickIntentSupport.modelContext.insert(record)
        try QuickIntentSupport.modelContext.save()

        return .result(dialog: "\(baby.name) için uyku başlatıldı.")
    }
}

// MARK: - Feeding

struct StartFeedingIntent: AppIntent {
    static let title: LocalizedStringResource = "Emzirme Başlat"
    static let description = IntentDescription("Bebeğiniz için yeni bir emzirme kaydı başlatır.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let baby = try QuickIntentSupport.resolveTargetBaby()

        let record = FeedingRecord(
            babyID: baby.id,
            type: .breast,
            startedAt: .now,
            endedAt: nil,
            durationSeconds: nil,
            side: .left
        )
        QuickIntentSupport.modelContext.insert(record)
        try QuickIntentSupport.modelContext.save()

        return .result(dialog: "\(baby.name) için emzirme başlatıldı.")
    }
}

// MARK: - Diaper

struct LogDiaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Bez Değişimi"
    static let description = IntentDescription("Bebeğiniz için bez değişimi kaydı ekler.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let baby = try QuickIntentSupport.resolveTargetBaby()

        let record = DiaperRecord(
            babyID: baby.id,
            recordedAt: .now,
            type: .pee
        )
        QuickIntentSupport.modelContext.insert(record)
        try QuickIntentSupport.modelContext.save()

        return .result(dialog: "\(baby.name) için bez değişimi kaydedildi.")
    }
}
