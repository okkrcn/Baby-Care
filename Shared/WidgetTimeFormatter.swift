import Foundation

/// Widget'lardaki "ne kadar önce" metinleri. Uygulama testlerinden de erişilsin
/// diye ortak koddadır (`Shared/`).
nonisolated enum WidgetTimeFormatter {
    /// 135 dk → "2 sa 15 dk", 40 dk → "40 dk", 1 dk altı → "Az önce".
    /// 24 saat ve üstü gün olarak yazılır: "3 gün". Uzun süre kayıt girilmemişse
    /// "1636 sa 50 dk" gibi taşan metinler oluşmasın.
    static func elapsed(seconds rawSeconds: Int) -> String {
        let seconds = max(0, rawSeconds)
        if seconds < 60 { return "Az önce" }
        if seconds >= 86_400 { return "\(seconds / 86_400) gün" }
        return DurationFormatter.string(fromSeconds: seconds)
    }

    /// "40 dk önce", "3 gün önce", "Az önce".
    static func ago(seconds: Int) -> String {
        let text = elapsed(seconds: seconds)
        return text == "Az önce" ? text : "\(text) önce"
    }

    /// Kilit ekranı yuvarlağı için kısa biçim: "45 dk", "2 sa", "3 g".
    static func compact(seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        if minutes < 60 { return "\(minutes) dk" }
        if minutes < 1_440 { return "\(minutes / 60) sa" }
        return "\(minutes / 1_440) g"
    }
}
