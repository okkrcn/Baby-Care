import Foundation

/// Bebeğin bakım dönemi. Yaşa bağlı tüm UI kapıları ve içerik seçimleri
/// buradan okunur — `ageInMonths >= 6` kontrolünün view'lara dağılmaması için.
enum BabyStage: String, CaseIterable, Sendable {
    case newborn        // 0–6 ay: yalnız anne sütü / mama
    case complementary  // 6–12 ay: ek gıdaya geçiş
    case toddler        // 12 ay ve üzeri

    var localizedTitle: String {
        switch self {
        case .newborn:       return "Yenidoğan (0–6 ay)"
        case .complementary: return "Ek gıda dönemi (6–12 ay)"
        case .toddler:       return "Oyun çocuğu (12–24 ay)"
        }
    }

    /// Ek gıda özelliklerinin görünür olup olmadığı.
    /// DSÖ ve TÜBER 2022: tamamlayıcı beslenme 6. ay dolunca başlar.
    var isSolidFoodAge: Bool {
        self != .newborn
    }

    static func forAgeMonths(_ months: Int) -> BabyStage {
        switch months {
        case ..<6:   return .newborn
        case 6..<12: return .complementary
        default:     return .toddler
        }
    }
}

extension Baby {
    var stage: BabyStage {
        BabyStage.forAgeMonths(ageInMonths)
    }
}
