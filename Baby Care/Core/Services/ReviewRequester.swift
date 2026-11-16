import Foundation
import SwiftUI
import StoreKit
#if os(iOS)
import UIKit
#endif

/// Akıllı App Store puanlama isteme yardımcısı.
///
/// Strateji:
/// - Kullanıcının kendi girdiği bakım kaydı içeren her başarılı kayıt bir etkileşim sayılır
///   (ana sayfa, takip ekranı, widget, Live Activity, Siri; hangi yoldan gelirse gelsin).
///   Sayım `TrackingSurfaceSync`'in `didSave` gözlemcisinden yapılır.
/// - İlk istek: 7 etkileşimden sonra
/// - Sonraki: 30 günde 1'den fazla istek yok
/// - Apple zaten yıllık 3 istek limitini kendisi uygular
/// - Uygulama ön planda değilse (widget, Siri) istenmez; sayım birikir, bir sonraki
///   ön plan kaydında değerlendirilir.
@MainActor
enum ReviewRequester {
    private static let recordCountKey = "review.recordCount"
    private static let lastRequestKey = "review.lastRequest"
    static let firstRequestThreshold = 7
    static let minimumDaysBetweenRequests = 30

    /// Puan istemeye değer kayıt türleri. Aşı takvimi gibi uygulamanın kendi
    /// ürettiği toplu kayıtlar ve profil düzenlemeleri sayılmaz.
    static let countedEntityNames: Set<String> = [
        "FeedingRecord", "SleepRecord", "DiaperRecord", "SolidFoodRecord",
        "GrowthRecord", "MedicationDose", "BreastMilkBatch", "ToothEruption",
    ]

    /// Bir kayıt işlemi kullanıcı etkileşimi sayılır mı? Yedekten geri yükleme gibi
    /// toplu eklemeler de tek etkileşim sayılır.
    static func isInteraction(insertedEntityNames: [String]) -> Bool {
        insertedEntityNames.contains { countedEntityNames.contains($0) }
    }

    /// Saf karar fonksiyonu (test edilir).
    static func shouldRequest(count: Int, lastRequest: Date?, now: Date) -> Bool {
        guard count >= firstRequestThreshold else { return false }
        guard let lastRequest else { return true }
        let days = Calendar.current.dateComponents([.day], from: lastRequest, to: now).day ?? 0
        return days >= minimumDaysBetweenRequests
    }

    /// Başarılı bir bakım kaydından sonra çağrılır.
    static func registerInteraction() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: recordCountKey) + 1
        defaults.set(count, forKey: recordCountKey)

        let lastRequest = defaults.object(forKey: lastRequestKey) as? Date
        guard shouldRequest(count: count, lastRequest: lastRequest, now: .now) else { return }

        #if os(iOS)
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        if let scene {
            AppStore.requestReview(in: scene)
            defaults.set(Date(), forKey: lastRequestKey)
        }
        #endif
    }
}
