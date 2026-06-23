import Foundation

/// Bebeğin günlük alması gereken anne sütü / mama miktarını
/// yaşına ve kilosuna göre hesaplar.
///
/// Formüller pediatri pratiğinde yaygın olarak kullanılan referans değerlerdir:
/// - İlk 1 hafta: artan günlük (60→100 ml/kg/gün)
/// - 1 hafta – 6 ay: 150–180 ml/kg/gün
///
/// Kaynak: AAP (American Academy of Pediatrics) Pediatric Nutrition Handbook,
/// T.C. Sağlık Bakanlığı Bebek Beslenmesi Rehberi.
/// Bu değerler bilgilendirme amaçlıdır; bebeğinizin gerçek ihtiyacı için
/// pediatristinize danışın. Bebek doyduğu kadar beslenmelidir.
enum FeedingCalculator {

    struct Result {
        let weightKg: Double
        let ageDays: Int
        let mlPerKgMin: Double
        let mlPerKgMax: Double
        let dailyMinML: Int
        let dailyMaxML: Int
        let dailyAverageML: Int

        /// Tipik öğün sayıları (yaşa göre öneri)
        let typicalFeedingsPerDay: Int

        /// Kalori (yaklaşık 67 kcal / 100 ml)
        let dailyCaloriesMin: Int
        let dailyCaloriesMax: Int

        /// Öğün başına ml (averagePerMeal[N öğün])
        func mlPerMeal(forFeedings n: Int) -> Int {
            guard n > 0 else { return 0 }
            return dailyAverageML / n
        }
    }

    /// İlk 7 gün için günlük ml/kg değeri (AAP yenidoğan referansı).
    private static func firstWeekMlPerKg(day: Int) -> Double {
        switch day {
        case 1: return 60
        case 2: return 80
        case 3...7: return 100
        default: return 150
        }
    }

    /// Bebeğin yaşına ve kilosuna göre günlük ihtiyacı hesaplar.
    /// - Parameters:
    ///   - ageDays: Bebeğin gün cinsinden yaşı (0 = doğum günü)
    ///   - weightKg: Güncel kilo (kg)
    static func calculate(ageDays: Int, weightKg: Double) -> Result {
        let kg = max(0.5, weightKg)

        let (minPerKg, maxPerKg): (Double, Double)

        if ageDays < 7 {
            let single = firstWeekMlPerKg(day: max(1, ageDays + 1))
            minPerKg = single
            maxPerKg = single
        } else {
            // 1 hafta - 6 ay arası standart aralık
            minPerKg = 150
            maxPerKg = 180
        }

        let dailyMin = minPerKg * kg
        let dailyMax = maxPerKg * kg
        let dailyAvg = (dailyMin + dailyMax) / 2

        // Tipik öğün sayısı yaşa göre
        let typicalFeedings: Int
        switch ageDays {
        case 0..<30:      typicalFeedings = 9   // 0-1 ay: 8-12, orta 9
        case 30..<90:     typicalFeedings = 7   // 1-3 ay: 6-8
        case 90..<180:    typicalFeedings = 5   // 3-6 ay: 4-6
        default:          typicalFeedings = 5
        }

        // Kalori: anne sütü ve standart mama ~67 kcal / 100 ml
        let kcalPer100ml: Double = 67
        let caloriesMin = Int((dailyMin / 100.0) * kcalPer100ml)
        let caloriesMax = Int((dailyMax / 100.0) * kcalPer100ml)

        return Result(
            weightKg: kg,
            ageDays: ageDays,
            mlPerKgMin: minPerKg,
            mlPerKgMax: maxPerKg,
            dailyMinML: Int(dailyMin.rounded()),
            dailyMaxML: Int(dailyMax.rounded()),
            dailyAverageML: Int(dailyAvg.rounded()),
            typicalFeedingsPerDay: typicalFeedings,
            dailyCaloriesMin: caloriesMin,
            dailyCaloriesMax: caloriesMax
        )
    }
}
