import Foundation

enum DateFormatters {
    /// "yyyy-MM-dd" — Postgres `date` kolonu için
    static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// "HH:mm:ss" — Postgres `time` kolonu için
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// Kullanıcıya gösterim — Türkçe, tam tarih
    static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    /// Kullanıcıya gösterim — Türkçe, kısa saat
    static let displayTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}
