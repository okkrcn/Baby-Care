import SwiftUI

/// Uygulamadaki kategori renkleriyle aynı: beslenme mavi, uyku indigo, bez yeşil.
enum WidgetPalette {
    static let feeding = Color.blue
    static let sleep = Color.indigo
    static let diaper = Color.green
}

enum WidgetText {
    private static let turkish = Locale(identifier: "tr_TR")

    /// 135 dk → "2 sa 15 dk", 40 dk → "40 dk", 1 dk altı → "Az önce".
    static func elapsed(since date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 { return "Az önce" }
        return DurationFormatter.string(fromSeconds: seconds)
    }

    /// "40 dk önce", "Az önce".
    static func ago(_ date: Date, now: Date) -> String {
        let text = elapsed(since: date, now: now)
        return text == "Az önce" ? text : "\(text) önce"
    }

    /// Kilit ekranı yuvarlağı için kısa biçim: "45 dk", "2 sa".
    static func compact(since date: Date, now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date)) / 60)
        return minutes < 60 ? "\(minutes) dk" : "\(minutes / 60) sa"
    }

    static func clock(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(turkish))
    }
}
