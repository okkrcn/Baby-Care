import Testing
@testable import Baby_Care

struct WHOPercentileTests {

    /// Altı tablonun tamamı: (metrik, cinsiyet) çiftleri.
    private static let allTables: [(WHOPercentiles.Metric, WHOPercentiles.Sex)] = [
        (.weight, .female), (.weight, .male),
        (.height, .female), (.height, .male),
        (.head,   .female), (.head,   .male)
    ]

    @Test func everyTableCoversZeroToTwentyFourMonths() {
        for (metric, sex) in Self.allTables {
            let rows = WHOPercentiles.data(for: metric, sex: sex)
            #expect(rows.count == 25, "\(metric)/\(sex): 25 satır bekleniyor, \(rows.count) var")
            #expect(rows.map(\.month) == Array(0...24),
                    "\(metric)/\(sex): aylar 0...24 sırasında değil")
        }
    }

    @Test func percentilesAreMonotonicWithinEachRow() {
        for (metric, sex) in Self.allTables {
            for row in WHOPercentiles.data(for: metric, sex: sex) {
                #expect(row.p3 < row.p15, "\(metric)/\(sex) ay \(row.month): p3 < p15 değil")
                #expect(row.p15 < row.p50, "\(metric)/\(sex) ay \(row.month): p15 < p50 değil")
                #expect(row.p50 < row.p85, "\(metric)/\(sex) ay \(row.month): p50 < p85 değil")
                #expect(row.p85 < row.p97, "\(metric)/\(sex) ay \(row.month): p85 < p97 değil")
            }
        }
    }

    @Test func medianGrowsMonotonicallyAcrossMonths() {
        // Kilo ve boy medyanı yaşla artar; küçülme veri giriş hatasıdır.
        for (metric, sex) in Self.allTables where metric != .head {
            let rows = WHOPercentiles.data(for: metric, sex: sex)
            for (prev, next) in zip(rows, rows.dropFirst()) {
                #expect(next.p50 > prev.p50,
                        "\(metric)/\(sex): ay \(next.month) medyanı ay \(prev.month)'dan düşük")
            }
        }
    }

    @Test func returnsNilBeyondTableRange() {
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .female, ageMonths: 25, value: 12.0
        )
        #expect(band == nil)
    }

    @Test func returnsNilForNegativeAge() {
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .male, ageMonths: -1, value: 3.0
        )
        #expect(band == nil)
    }

    @Test func classifiesMedianValueAsNormalRange() {
        let rows = WHOPercentiles.data(for: .weight, sex: .male)
        let month12 = rows.first { $0.month == 12 }!
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .male, ageMonths: 12, value: month12.p50
        )
        #expect(band == "15–85. persentil (normal aralık)")
    }

    @Test func classifiesBelowThirdPercentile() {
        let rows = WHOPercentiles.data(for: .weight, sex: .female)
        let month18 = rows.first { $0.month == 18 }!
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .female, ageMonths: 18, value: month18.p3 - 0.5
        )
        #expect(band == "< 3. persentil")
    }

    @Test func classifiesAboveNinetySeventhPercentile() {
        let rows = WHOPercentiles.data(for: .head, sex: .male)
        let month24 = rows.first { $0.month == 24 }!
        let band = WHOPercentiles.percentileBand(
            metric: .head, sex: .male, ageMonths: 24, value: month24.p97 + 1.0
        )
        #expect(band == "> 97. persentil")
    }

    @Test func maxAgeMonthsIsTwentyFour() {
        #expect(WHOPercentiles.maxAgeMonths == 24)
    }

    @Test func matchesOfficialWHOValuesAtSampledAges() {
        // WHO Child Growth Standards, ay bazlı persentil tabloları.
        // Kaynak: who.int/tools/child-growth-standards/standards
        let weightMale12 = WHOPercentiles.data(for: .weight, sex: .male)[12]
        #expect(weightMale12.p50 == 9.6)

        let heightFemale24 = WHOPercentiles.data(for: .height, sex: .female)[24]
        #expect(heightFemale24.p50 == 86.4)

        let headMale18 = WHOPercentiles.data(for: .head, sex: .male)[18]
        #expect(headMale18.p50 == 47.4)
    }
}
