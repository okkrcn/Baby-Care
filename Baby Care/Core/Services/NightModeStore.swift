import Foundation
import Observation

/// Gece modu tercihi ve otomatik tetikleyici.
@MainActor
@Observable
final class NightModeStore {
    enum Mode: String, CaseIterable, Sendable {
        case auto      // Saat tabanlı (21:00 – 07:00)
        case alwaysOn  // Her zaman açık
        case alwaysOff // Kapalı

        var label: String {
            switch self {
            case .auto:      return "Otomatik (21:00–07:00)"
            case .alwaysOn:  return "Her zaman açık"
            case .alwaysOff: return "Kapalı"
            }
        }
    }

    private static let storageKey = "nightMode.preference"

    var mode: Mode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Mode.auto.rawValue
        self.mode = Mode(rawValue: raw) ?? .auto
    }

    /// Mevcut saate göre gece modu aktif mi?
    var isActive: Bool {
        switch mode {
        case .alwaysOn:  return true
        case .alwaysOff: return false
        case .auto:
            let hour = Calendar.current.component(.hour, from: .now)
            return hour >= 21 || hour < 7
        }
    }
}
