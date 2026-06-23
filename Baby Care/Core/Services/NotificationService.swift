import Foundation
import UserNotifications

/// Aşı hatırlatma bildirimleri için sarmal.
///
/// Plan: Her aşı için 3 bildirim — 3 gün öncesi 09:00, 1 gün öncesi 09:00, gün 08:00.
/// Bildirim identifier'ı `"vaccine_<recordID>_<offsetDays>"` formatındadır,
/// böylece tek aşı için tüm bekleyenleri toplu silebiliriz.
@MainActor
enum NotificationService {
    private static let offsets: [(days: Int, hour: Int, minute: Int)] = [
        (-3, 9, 0),
        (-1, 9, 0),
        ( 0, 8, 0)
    ]

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func scheduleReminders(for record: VaccinationRecord, babyName: String) async {
        // Mevcut bildirimleri sil ki çakışma olmasın
        await cancelReminders(for: record)

        guard let def = record.definition,
              record.completedDate == nil else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let calendar = Calendar.current
        let center = UNUserNotificationCenter.current()

        for offset in offsets {
            guard let triggerDate = calendar.date(byAdding: .day, value: offset.days, to: record.scheduledDate) else {
                continue
            }
            var components = calendar.dateComponents([.year, .month, .day], from: triggerDate)
            components.hour = offset.hour
            components.minute = offset.minute

            // Geçmiş tarihler için bildirim planlama
            if let fire = calendar.date(from: components), fire < .now {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = babyName + " — Aşı Hatırlatması"
            content.body = body(for: offset.days, vaccineName: def.shortName)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "vaccine_\(record.id.uuidString)_\(offset.days)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await center.add(request)
        }
    }

    static func cancelReminders(for record: VaccinationRecord) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "vaccine_\(record.id.uuidString)_"
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func rescheduleAll(for babyName: String, records: [VaccinationRecord]) async {
        for record in records where record.completedDate == nil {
            await scheduleReminders(for: record, babyName: babyName)
        }
    }

    private static func body(for offsetDays: Int, vaccineName: String) -> String {
        switch offsetDays {
        case -3: return "\(vaccineName) için 3 gün kaldı."
        case -1: return "\(vaccineName) yarın yapılacak."
        case  0: return "Bugün \(vaccineName) aşısı günü."
        default: return "\(vaccineName) hatırlatması."
        }
    }

    // MARK: - Medication reminders

    static func scheduleDailyReminder(for med: Medication, babyName: String) async {
        await cancelReminders(for: med)
        guard med.isActive else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(babyName) — \(med.name)"
        content.body = med.dosageText
        content.sound = .default

        var components = DateComponents()
        components.hour = med.reminderHour
        components.minute = med.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let identifier = "medication_\(med.id.uuidString)_daily"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminders(for med: Medication) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "medication_\(med.id.uuidString)_"
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func rescheduleAll(for babyName: String, medications: [Medication]) async {
        for med in medications where med.isActive {
            await scheduleDailyReminder(for: med, babyName: babyName)
        }
    }

    // MARK: - Milk storage expiry reminders

    static func scheduleExpiryReminder(for batch: BreastMilkBatch, babyName: String) async {
        await cancelExpiryReminder(for: batch)
        guard batch.isActive else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        // Bitiş 30 dakika öncesi
        let triggerDate = batch.expiresAt.addingTimeInterval(-30 * 60)
        guard triggerDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(babyName) — Sağılmış Süt"
        content.body = "\(batch.amountML) ml sütün süresi 30 dakika içinde doluyor. \(batch.storage.localizedTitle) konumunda."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "milk_\(batch.id.uuidString)_expiry"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelExpiryReminder(for batch: BreastMilkBatch) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "milk_\(batch.id.uuidString)_"
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Weekly summary (Pazar 19:00)

    static func scheduleWeeklySummary() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Baby Care — Haftalık Özet"
        content.body = "Bu hafta nasıl geçti? Bebeğinizin haftalık özetini görmek için açın."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1   // Pazar (Calendar.current weekday: 1=Pazar)
        components.hour = 19
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancelWeeklySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])
    }

    // MARK: - Weekly growth measurement reminder (Pazar 10:00)

    static func scheduleWeeklyGrowthReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_growth"])

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Baby Care — Büyüme Ölçümü"
        content.body = "Haftalık ölçüm zamanı: bebeğinizin kilo, boy ve baş çevresini kaydedin."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1   // Pazar
        components.hour = 10
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_growth", content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func cancelWeeklyGrowthReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_growth"])
    }
}
