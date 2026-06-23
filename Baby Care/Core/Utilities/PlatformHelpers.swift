import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Hızlı kayıt gibi anlık eylemlerde dokunsal geri bildirim sağlar.
/// macOS'ta no-op olur (haptic motoru yok).
enum Haptics {
    /// Başarılı bir kayıt sonrası kısa "başarılı" dokunuşu.
    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

/// iOS ve macOS arasında platform-spesifik modifier'ları sarmalayan yardımcılar.
/// Target hem iPhone hem Mac olduğu için bu sayede tek view kodu yazılabilir.
extension View {
    @ViewBuilder
    func numericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
