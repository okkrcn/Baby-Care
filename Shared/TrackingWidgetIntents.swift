#if os(iOS)
import AppIntents
import Foundation

// Widget ve Live Activity düğmelerinin intent'leri.
//
// Bu dosya hem uygulamaya hem widget uzantısına derlenir. `LiveActivityIntent`
// uyumu sayesinde sistem `perform()`'u uygulamanın kendi sürecinde çalıştırır;
// kayıt mantığı (`WidgetActionPerformer`) yalnızca uygulamada bulunur.
// Uzantı derlemesinde `WIDGET_EXTENSION` tanımlıdır ve gövde boş kalır.

// Parametreler düz `String` olarak taşınır: AppEnum değerleri widget sürecinden
// uygulama sürecine geçerken çözümlenemiyor (simülatörde `nil` geldi).

nonisolated enum WidgetDiaperKind: String, Sendable {
    case pee
    case poo
}

nonisolated enum WidgetTimerKind: String, Sendable {
    case feeding
    case sleep
}

/// Emzirme yoksa başlatır, varsa bitirir.
struct ToggleFeedingWidgetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Emzirmeyi başlat veya bitir"
    static let isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        try WidgetActionPerformer.toggleFeeding()
        #endif
        return .result()
    }
}

/// Uyku yoksa başlatır, varsa bitirir.
struct ToggleSleepWidgetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Uykuyu başlat veya bitir"
    static let isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        try WidgetActionPerformer.toggleSleep()
        #endif
        return .result()
    }
}

/// Anlık bez değişimi kaydeder.
struct LogDiaperWidgetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Bez değişimi kaydet"
    static let isDiscoverable = false

    @Parameter(title: "Bez türü")
    var kindRaw: String

    init() {}

    init(kind: WidgetDiaperKind) {
        self.kindRaw = kind.rawValue
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        if let kind = WidgetDiaperKind(rawValue: kindRaw) {
            try WidgetActionPerformer.logDiaper(kind)
        }
        #endif
        return .result()
    }
}

/// Live Activity'deki "Bitir" / "Uyandı" düğmesi: belirli bir kaydı bitirir.
struct EndTrackingTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Sayacı bitir"
    static let isDiscoverable = false

    @Parameter(title: "Kayıt")
    var recordID: String

    @Parameter(title: "Sayaç")
    var kindRaw: String

    init() {}

    init(recordID: UUID, kind: WidgetTimerKind) {
        self.recordID = recordID.uuidString
        self.kindRaw = kind.rawValue
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        if let id = UUID(uuidString: recordID), let kind = WidgetTimerKind(rawValue: kindRaw) {
            try WidgetActionPerformer.endTimer(recordID: id, kind: kind)
        }
        #endif
        return .result()
    }
}
#endif
