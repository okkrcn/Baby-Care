import Foundation

/// Dünya Sağlık Örgütü (WHO) Çocuk Büyüme Standartları — 0-6 ay.
///
/// Yüzdelikler: 3, 15, 50, 85, 97. Veriler ay başlangıcı içindir.
/// Kaynak: WHO Child Growth Standards (https://www.who.int/tools/child-growth-standards).
/// Bu değerler bilgilendirme amaçlıdır; klinik kararlar pediatristin yorumuna dayanmalıdır.
enum WHOPercentiles {
    enum Sex {
        case female, male

        init(from babySex: BabySex) {
            switch babySex {
            case .female: self = .female
            case .male, .unspecified: self = .male
            }
        }
    }

    enum Metric {
        case weight    // kg
        case height    // cm
        case head      // cm

        var unitLabel: String {
            switch self {
            case .weight: return "kg"
            case .height: return "cm"
            case .head:   return "cm"
            }
        }

        var title: String {
            switch self {
            case .weight: return "Kilo"
            case .height: return "Boy"
            case .head:   return "Baş Çevresi"
            }
        }
    }

    /// (ay, P3, P15, P50, P85, P97)
    typealias Row = (month: Int, p3: Double, p15: Double, p50: Double, p85: Double, p97: Double)

    // MARK: - Weight for age (kg)

    static let weightFemale: [Row] = [
        (0, 2.4, 2.8, 3.2, 3.7, 4.2),
        (1, 3.2, 3.6, 4.2, 4.8, 5.5),
        (2, 4.0, 4.5, 5.1, 5.8, 6.6),
        (3, 4.6, 5.1, 5.8, 6.6, 7.5),
        (4, 5.1, 5.6, 6.4, 7.3, 8.2),
        (5, 5.5, 6.1, 6.9, 7.8, 8.8),
        (6, 5.8, 6.4, 7.3, 8.2, 9.3)
    ]

    static let weightMale: [Row] = [
        (0, 2.5, 2.9, 3.3, 3.9, 4.4),
        (1, 3.4, 3.9, 4.5, 5.1, 5.8),
        (2, 4.4, 4.9, 5.6, 6.3, 7.1),
        (3, 5.1, 5.7, 6.4, 7.2, 8.0),
        (4, 5.6, 6.2, 7.0, 7.8, 8.7),
        (5, 6.1, 6.7, 7.5, 8.4, 9.3),
        (6, 6.4, 7.1, 7.9, 8.8, 9.8)
    ]

    // MARK: - Length for age (cm)

    static let heightFemale: [Row] = [
        (0, 45.6, 47.2, 49.1, 51.1, 52.7),
        (1, 50.0, 51.7, 53.7, 55.7, 57.4),
        (2, 53.2, 55.0, 57.1, 59.2, 61.0),
        (3, 55.8, 57.6, 59.8, 62.0, 63.8),
        (4, 58.0, 59.8, 62.1, 64.3, 66.2),
        (5, 59.9, 61.7, 64.0, 66.3, 68.2),
        (6, 61.5, 63.4, 65.7, 68.1, 70.0)
    ]

    static let heightMale: [Row] = [
        (0, 46.1, 47.9, 49.9, 51.8, 53.7),
        (1, 50.8, 52.7, 54.7, 56.7, 58.6),
        (2, 54.4, 56.4, 58.4, 60.4, 62.4),
        (3, 57.3, 59.3, 61.4, 63.5, 65.5),
        (4, 59.7, 61.7, 63.9, 66.0, 68.0),
        (5, 61.7, 63.8, 65.9, 68.1, 70.1),
        (6, 63.3, 65.5, 67.6, 69.8, 71.9)
    ]

    // MARK: - Head circumference for age (cm)

    static let headFemale: [Row] = [
        (0, 31.7, 32.7, 33.9, 35.1, 36.1),
        (1, 34.3, 35.3, 36.5, 37.8, 38.8),
        (2, 36.0, 37.0, 38.3, 39.5, 40.5),
        (3, 37.2, 38.3, 39.5, 40.8, 41.9),
        (4, 38.2, 39.3, 40.6, 41.8, 42.9),
        (5, 39.0, 40.1, 41.5, 42.7, 43.8),
        (6, 39.7, 40.8, 42.2, 43.5, 44.6)
    ]

    static let headMale: [Row] = [
        (0, 32.1, 33.1, 34.5, 35.8, 36.9),
        (1, 34.9, 35.9, 37.3, 38.4, 39.5),
        (2, 36.8, 37.9, 39.1, 40.3, 41.5),
        (3, 38.1, 39.3, 40.5, 41.7, 42.9),
        (4, 39.2, 40.4, 41.6, 42.8, 44.0),
        (5, 40.1, 41.4, 42.6, 43.8, 45.0),
        (6, 40.9, 42.1, 43.3, 44.6, 45.8)
    ]

    // MARK: - Lookup

    static func data(for metric: Metric, sex: Sex) -> [Row] {
        switch (metric, sex) {
        case (.weight, .female): return weightFemale
        case (.weight, .male):   return weightMale
        case (.height, .female): return heightFemale
        case (.height, .male):   return heightMale
        case (.head,   .female): return headFemale
        case (.head,   .male):   return headMale
        }
    }

    /// Verilen ay ve değer için yaklaşık persentil bandını döner.
    /// < P3, P3-P15, P15-P85 (normal), P85-P97, > P97
    static func percentileBand(metric: Metric, sex: Sex, ageMonths: Int, value: Double) -> String {
        let rows = data(for: metric, sex: sex)
        let clamped = max(0, min(rows.count - 1, ageMonths))
        let row = rows[clamped]

        if value < row.p3 { return "< 3.persentil" }
        if value < row.p15 { return "3–15. persentil" }
        if value <= row.p85 { return "15–85. persentil (normal aralık)" }
        if value <= row.p97 { return "85–97. persentil" }
        return "> 97.persentil"
    }
}
