import Foundation
import SwiftData

/// Tek-dokunuşla hızlı kayıt mantığını merkezîleştirir.
///
/// Ana sayfa (Dashboard) ile Takip ekranı aynı davranışı paylaşsın ve
/// `save()` hataları sessizce yutulmasın diye toggle/kaydet işlemleri burada
/// toplanmıştır. Her fonksiyon hata fırlatır; çağıran taraf kullanıcıya bildirir.
enum QuickLogService {

    /// Devam eden uyku varsa bitirir, yoksa içinde bulunulan saate göre
    /// (gündüz şekerleme / gece uykusu) yeni bir uyku başlatır.
    /// - Returns: Kullanıcıya gösterilecek kısa geri bildirim metni.
    @discardableResult
    static func toggleSleep(for baby: Baby, ongoing: SleepRecord?, in context: ModelContext) throws -> String {
        if let ongoing {
            return try endSleep(ongoing, in: context)
        } else {
            let hour = Calendar.current.component(.hour, from: .now)
            let isNap = hour >= 7 && hour < 19
            let record = SleepRecord(babyID: baby.id, startedAt: .now, endedAt: nil, isNap: isNap)
            context.insert(record)
            try context.save()
            return isNap ? "Gündüz uykusu başlatıldı" : "Gece uykusu başlatıldı"
        }
    }

    /// Devam eden emzirme varsa bitirir (süreyi hesaplar), yoksa sol göğüsten
    /// yeni bir emzirme başlatır.
    /// - Returns: Kullanıcıya gösterilecek kısa geri bildirim metni.
    @discardableResult
    static func toggleFeeding(for baby: Baby, ongoing: FeedingRecord?, in context: ModelContext) throws -> String {
        if let ongoing {
            return try endFeeding(ongoing, in: context)
        } else {
            let record = FeedingRecord(
                babyID: baby.id,
                type: .breast,
                startedAt: .now,
                endedAt: nil,
                durationSeconds: nil,
                side: .left
            )
            context.insert(record)
            try context.save()
            return "Emzirme başlatıldı (sol)"
        }
    }

    /// Devam eden uykuyu şimdi bitirir.
    @discardableResult
    static func endSleep(_ record: SleepRecord, in context: ModelContext) throws -> String {
        record.endedAt = .now
        record.updatedAt = .now
        try context.save()
        return "Uyku bitirildi: \(DurationFormatter.string(fromSeconds: record.durationSeconds))"
    }

    /// Devam eden emzirmeyi şimdi bitirir ve süresini hesaplar.
    @discardableResult
    static func endFeeding(_ record: FeedingRecord, in context: ModelContext) throws -> String {
        let now = Date()
        record.endedAt = now
        record.durationSeconds = max(1, Int(now.timeIntervalSince(record.startedAt)))
        record.updatedAt = now
        try context.save()
        return "Emzirme bitirildi: \(DurationFormatter.string(fromSeconds: record.durationSeconds ?? 0))"
    }

    /// Verilen miktarda (CC/ml) biberon beslemesi kaydeder.
    /// - Parameter type: `.bottleBreastmilk` (sağılmış süt) veya `.bottleFormula` (mama).
    /// - Returns: Kullanıcıya gösterilecek kısa geri bildirim metni.
    @discardableResult
    static func logBottle(_ type: FeedingType, amountML: Int, for baby: Baby, in context: ModelContext) throws -> String {
        let record = FeedingRecord(
            babyID: baby.id,
            type: type,
            startedAt: .now,
            endedAt: .now,
            durationSeconds: nil,
            side: nil,
            amountML: amountML
        )
        context.insert(record)
        try context.save()
        return "\(type.localizedTitle) · \(amountML) ml kaydedildi"
    }

    /// Verilen türde anlık bir bez değişimi kaydeder.
    /// - Returns: Kullanıcıya gösterilecek kısa geri bildirim metni.
    @discardableResult
    static func logDiaper(_ type: DiaperType, for baby: Baby, in context: ModelContext) throws -> String {
        let record = DiaperRecord(babyID: baby.id, recordedAt: .now, type: type)
        context.insert(record)
        try context.save()
        return "Bez değişimi kaydedildi (\(type.localizedTitle.lowercased()))"
    }
}
