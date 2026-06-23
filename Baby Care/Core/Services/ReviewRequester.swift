import Foundation
import SwiftUI
import StoreKit
#if os(iOS)
import UIKit
#endif

/// Akıllı App Store puanlama isteme yardımcısı.
///
/// Strateji:
/// - İlk istek: 7 kayıt eklendikten sonra
/// - Sonraki: 30 günde 1'den fazla istek yok
/// - Apple zaten yıllık 3 istek limitini kendisi uygular
@MainActor
enum ReviewRequester {
    private static let recordCountKey = "review.recordCount"
    private static let lastRequestKey = "review.lastRequest"
    private static let firstRequestThreshold = 7

    /// Kullanıcı bir kayıt eklediğinde çağırın.
    static func registerInteraction() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: recordCountKey) + 1
        defaults.set(count, forKey: recordCountKey)

        let lastRequest = defaults.object(forKey: lastRequestKey) as? Date

        // İlk eşik
        guard count >= firstRequestThreshold else { return }

        // 30 günde bir
        if let last = lastRequest {
            let days = Calendar.current.dateComponents([.day], from: last, to: .now).day ?? 0
            guard days >= 30 else { return }
        }

        // Mevcut sahneye iste
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
