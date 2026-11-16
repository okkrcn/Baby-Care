import SwiftUI

/// Uygulamadaki kategori renkleriyle aynı: beslenme mavi, uyku indigo, bez yeşil.
enum WidgetPalette {
    static let feeding = Color.blue
    static let sleep = Color.indigo
    static let diaper = Color.green
}

enum WidgetText {
    private static let turkish = Locale(identifier: "tr_TR")

    static func elapsed(since date: Date, now: Date) -> String {
        WidgetTimeFormatter.elapsed(seconds: Int(now.timeIntervalSince(date)))
    }

    static func ago(_ date: Date, now: Date) -> String {
        WidgetTimeFormatter.ago(seconds: Int(now.timeIntervalSince(date)))
    }

    static func compact(since date: Date, now: Date) -> String {
        WidgetTimeFormatter.compact(seconds: Int(now.timeIntervalSince(date)))
    }

    static func clock(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(turkish))
    }
}
