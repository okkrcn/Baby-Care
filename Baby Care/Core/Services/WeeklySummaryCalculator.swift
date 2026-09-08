import Foundation

/// Bebeğin son 7 günü için özet hesaplaması.
struct WeeklySummary: Sendable {
    let baby: Baby
    let weekStart: Date
    let weekEnd: Date

    let totalFeedings: Int
    let totalBreastfeedingSeconds: Int
    let totalBottleML: Int
    let averageFeedingsPerDay: Double

    let totalSleepSeconds: Int
    let averageSleepHoursPerDay: Double
    let nightSleepCount: Int
    let napCount: Int

    let totalDiapers: Int
    let averageDiapersPerDay: Double

    let weightChangeGrams: Int?   // varsa son ölçüm vs geçen hafta sonu
    let heightChangeCm: Double?

    let completedVaccinations: Int

    /// Ek gıda dönemi (6 ay+) için; küçük bebekte sıfır kalır.
    let solidFoodMeals: Int
    let newFoodsTried: Int
}

@MainActor
enum WeeklySummaryCalculator {
    static func calculate(
        for baby: Baby,
        feedings: [FeedingRecord],
        sleeps: [SleepRecord],
        diapers: [DiaperRecord],
        growth: [GrowthRecord],
        vaccinations: [VaccinationRecord],
        solidFoods: [SolidFoodRecord],
        referenceDate: Date = .now
    ) -> WeeklySummary {
        let calendar = Calendar.current
        let weekEnd = calendar.startOfDay(for: referenceDate).addingTimeInterval(24 * 3600 - 1)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate

        let inRange: (Date) -> Bool = { $0 >= weekStart && $0 <= weekEnd }

        let weekFeedings = feedings.filter { $0.babyID == baby.id && inRange($0.startedAt) }
        let breastSeconds = weekFeedings.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
        let bottleML = weekFeedings.reduce(0) { $0 + ($1.amountML ?? 0) }

        let weekSleeps = sleeps.filter { $0.babyID == baby.id && inRange($0.startedAt) && !$0.isOngoing }
        let sleepSeconds = weekSleeps.reduce(0) { $0 + $1.durationSeconds }

        let weekDiapers = diapers.filter { $0.babyID == baby.id && inRange($0.recordedAt) }

        let napCount = weekSleeps.filter { $0.isNap }.count
        let nightCount = weekSleeps.filter { !$0.isNap }.count

        // Büyüme deltası
        let babyGrowth = growth.filter { $0.babyID == baby.id }.sorted { $0.recordedAt < $1.recordedAt }
        let thisWeekMeas = babyGrowth.last { inRange($0.recordedAt) }
        let previousMeas = babyGrowth.last { $0.recordedAt < weekStart }

        var weightDelta: Int? = nil
        var heightDelta: Double? = nil
        if let cur = thisWeekMeas, let prev = previousMeas {
            if let curW = cur.weightGrams, let prevW = prev.weightGrams {
                weightDelta = curW - prevW
            }
            if let curH = cur.heightCm, let prevH = prev.heightCm {
                heightDelta = curH - prevH
            }
        }

        let weekSolids = solidFoods.filter { $0.babyID == baby.id && inRange($0.servedAt) }

        let completedVaccs = vaccinations.filter {
            $0.babyID == baby.id && ($0.completedDate.map(inRange) ?? false)
        }.count

        return WeeklySummary(
            baby: baby,
            weekStart: weekStart,
            weekEnd: weekEnd,
            totalFeedings: weekFeedings.count,
            totalBreastfeedingSeconds: breastSeconds,
            totalBottleML: bottleML,
            averageFeedingsPerDay: Double(weekFeedings.count) / 7.0,
            totalSleepSeconds: sleepSeconds,
            averageSleepHoursPerDay: Double(sleepSeconds) / 3600.0 / 7.0,
            nightSleepCount: nightCount,
            napCount: napCount,
            totalDiapers: weekDiapers.count,
            averageDiapersPerDay: Double(weekDiapers.count) / 7.0,
            weightChangeGrams: weightDelta,
            heightChangeCm: heightDelta,
            completedVaccinations: completedVaccs,
            solidFoodMeals: weekSolids.count,
            newFoodsTried: weekSolids.filter(\.isFirstTry).count
        )
    }
}
