import Foundation

/// `babycare://` bağlantıları. Uygulama içi etkinlikler, widget ve paylaşılan
/// linkler uygulamayı ilgili sekmede açar.
///
/// Desteklenen: `babycare://ana`, `babycare://takip`, `babycare://asi`,
/// `babycare://bebek`, `babycare://dis` (Bebek sekmesinde Diş Gelişimi).
/// Tanınmayan yol ana sayfayı açar; bağlantı uygulamayı hiçbir zaman çökertmez.
enum AppTab: Hashable {
    case home, tracking, vaccination, baby, settings
}

enum DeepLink: Equatable {
    case tab(AppTab)
    case teeth

    static let scheme = "babycare"

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }
        // babycare://dis ve babycare:///dis ikisi de kabul edilir.
        let key = (url.host() ?? url.pathComponents.dropFirst().first ?? "").lowercased()
        switch key {
        case "takip": self = .tab(.tracking)
        case "asi", "aşı": self = .tab(.vaccination)
        case "bebek": self = .tab(.baby)
        case "ayarlar": self = .tab(.settings)
        case "dis", "diş": self = .teeth
        default: self = .tab(.home)
        }
    }

    var tab: AppTab {
        switch self {
        case .tab(let tab): return tab
        case .teeth: return .baby
        }
    }
}
