import Testing
import Foundation
@testable import Baby_Care

struct GuideCatalogTests {

    @Test func stagesCoverBirthToTwentyFourMonthsWithoutGaps() {
        let stages = GuideCatalog.stages
        #expect(stages.first?.minWeeks == 0)
        for (prev, next) in zip(stages, stages.dropFirst()) {
            #expect(next.minWeeks == prev.maxWeeks,
                    "\(prev.id) → \(next.id) arasında boşluk veya çakışma var")
        }
        // Son aşama en az 104 haftayı (24 ay) kapsamalı
        #expect((stages.last?.maxWeeks ?? 0) >= 104)
    }

    @Test func outOfScopePlaceholderIsGone() {
        let joined = GuideCatalog.stages
            .flatMap { [$0.summary] + $0.grossMotor }
            .joined(separator: " ")
        #expect(!joined.contains("kapsamı dışında"))
    }

    @Test func everyStageHasContentInAllCategories() {
        for stage in GuideCatalog.stages {
            #expect(!stage.title.isEmpty, "\(stage.id): başlık boş")
            #expect(!stage.summary.isEmpty, "\(stage.id): özet boş")
            #expect(!stage.grossMotor.isEmpty, "\(stage.id): kaba motor boş")
            #expect(!stage.fineMotor.isEmpty, "\(stage.id): ince motor boş")
            #expect(!stage.language.isEmpty, "\(stage.id): dil boş")
            #expect(!stage.socialEmotional.isEmpty, "\(stage.id): sosyal-duygusal boş")
            #expect(!stage.feedingTips.isEmpty, "\(stage.id): beslenme boş")
            #expect(!stage.sleepTips.isEmpty, "\(stage.id): uyku boş")
            #expect(!stage.warningSigns.isEmpty, "\(stage.id): uyarı işaretleri boş")
        }
    }

    @Test func identifiersAreUnique() {
        let ids = GuideCatalog.stages.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func lookupResolvesSolidFoodAges() {
        // 30 hafta ≈ 7 ay, 60 hafta ≈ 14 ay, 100 hafta ≈ 23 ay
        #expect(GuideCatalog.stage(forAgeWeeks: 30).id == "stage_6_8m")
        #expect(GuideCatalog.stage(forAgeWeeks: 60).id == "stage_12_15m")
        #expect(GuideCatalog.stage(forAgeWeeks: 100).id == "stage_18_24m")
    }

    @Test func lookupClampsBeyondTwentyFourMonths() {
        // 3 yaşındaki bir çocukta son aşama dönmeli, çökmemeli
        #expect(GuideCatalog.stage(forAgeWeeks: 160).id == "stage_18_24m")
    }

    @Test func lookupStillResolvesNewbornAges() {
        #expect(GuideCatalog.stage(forAgeWeeks: 0).id == "stage_0_2w")
        #expect(GuideCatalog.stage(forAgeWeeks: 24).id == "stage_22_26w")
    }

    @Test func solidFoodStageMentionsIron() {
        // TÜBER 2022: 6. aydan itibaren demir kaynakları öncelikli.
        let sixToEight = GuideCatalog.stages.first { $0.id == "stage_6_8m" }!
        let joined = sixToEight.feedingTips.joined(separator: " ")
        #expect(joined.localizedCaseInsensitiveContains("demir"))
    }

    @Test func solidFoodStagesCarryAgeBarriers() {
        // Bal 12 ay, tuz/şeker uyarıları ek gıda aşamalarında görünmeli.
        let sixToEight = GuideCatalog.stages.first { $0.id == "stage_6_8m" }!
        let joined = sixToEight.feedingTips.joined(separator: " ")
        #expect(joined.localizedCaseInsensitiveContains("bal"))
        #expect(joined.localizedCaseInsensitiveContains("tuz"))
    }
}
