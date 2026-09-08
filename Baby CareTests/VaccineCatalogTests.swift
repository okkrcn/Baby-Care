import Testing
import Foundation
@testable import Baby_Care

struct VaccineCatalogTests {

    @Test func kpaIsTwoPlusOneSchedule() {
        // T.C. Sağlık Bakanlığı 2025 takvimi: KPA 2., 4. ay ve 12. ay rapel.
        // 6. ayda KPA yok — eski katalogda hatalı bir kpa_6m tanımı vardı.
        let kpaMonths = VaccineCatalog.scheduled
            .filter { $0.shortName.contains("KPA") }
            .map(\.scheduledAgeMonths)
            .sorted()
        #expect(kpaMonths == [2, 4, 12])
    }

    @Test func retiredKpaSixMonthDefinitionStillResolves() {
        // Mevcut kullanıcılarda kpa_6m kaydı olabilir; UI ham id göstermesin.
        let def = VaccineCatalog.definition(forID: "kpa_6m")
        #expect(def != nil)
        #expect(def?.isRetired == true)
    }

    @Test func retiredDefinitionsAreExcludedFromScheduling() {
        #expect(VaccineCatalog.scheduled.contains { $0.isRetired } == false)
    }

    @Test func ninthMonthMeaslesExtraDoseExists() {
        let ninth = VaccineCatalog.scheduled.filter { $0.scheduledAgeMonths == 9 }
        #expect(ninth.count == 1)
        #expect(ninth.first?.shortName.contains("KKK") == true)
    }

    @Test func twelfthMonthHasThreeVaccines() {
        let ids = Set(VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 12 }.map(\.id))
        #expect(ids == ["kpa_12m", "varicella_12m", "mmr_12m"])
    }

    @Test func eighteenthMonthHasThreeVaccines() {
        let ids = Set(VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 18 }.map(\.id))
        #expect(ids == ["hexa_18m", "opa_18m", "hepa_18m"])
    }

    @Test func twentyFourthMonthHasHepatitisASecondDose() {
        let ids = VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 24 }.map(\.id)
        #expect(ids == ["hepa_24m"])
    }

    @Test func sixthMonthHasOnlyHexaAndOpa() {
        let ids = Set(VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 6 }.map(\.id))
        #expect(ids == ["hexa_6m", "opa_6m"])
    }

    @Test func catalogStopsAtTwentyFourMonths() {
        // 48. ay ve 13 yaş aşıları kapsam dışı.
        #expect(VaccineCatalog.scheduled.allSatisfy { $0.scheduledAgeMonths <= 24 })
    }

    @Test func everyDefinitionHasNonEmptyContent() {
        for def in VaccineCatalog.schedule {
            #expect(!def.id.isEmpty)
            #expect(!def.shortName.isEmpty, "\(def.id): kısa ad boş")
            #expect(!def.fullName.isEmpty, "\(def.id): tam ad boş")
            #expect(!def.description.isEmpty, "\(def.id): açıklama boş")
            #expect(!def.route.isEmpty, "\(def.id): uygulama yolu boş")
        }
    }

    @Test func identifiersAreUnique() {
        let ids = VaccineCatalog.schedule.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
