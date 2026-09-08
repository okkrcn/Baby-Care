import Testing
import Foundation
@testable import Baby_Care

struct SafetyContentTests {

    // MARK: - Boğulma

    @Test func infantChokingScenarioStillExists() {
        #expect(FirstAidCatalog.scenarios.contains { $0.id == "choking" })
    }

    @Test func toddlerChokingScenarioIsAdded() {
        let toddler = FirstAidCatalog.scenarios.first { $0.id == "choking_toddler" }
        #expect(toddler != nil)
        #expect(toddler?.steps.isEmpty == false)
    }

    @Test func toddlerChokingUsesAbdominalThrusts() {
        // 1 yaş üstünde karın baskısı uygulanır; bebekte uygulanmaz.
        let toddler = FirstAidCatalog.scenarios.first { $0.id == "choking_toddler" }!
        let text = toddler.steps.map { $0.title + " " + ($0.detail ?? "") }
            .joined(separator: " ")
        #expect(text.localizedCaseInsensitiveContains("karın"))
    }

    @Test func infantChokingStillForbidsAbdominalThrusts() {
        let infant = FirstAidCatalog.scenarios.first { $0.id == "choking" }!
        let warnings = infant.warnings.joined(separator: " ")
        #expect(warnings.contains("Heimlich"))
    }

    @Test func gaggingIsDistinguishedFromChoking() {
        // Öğüren bebeğe müdahale edilmez; bu ayrım her iki senaryoda da olmalı.
        for id in ["choking", "choking_toddler"] {
            let scenario = FirstAidCatalog.scenarios.first { $0.id == id }!
            let text = ([scenario.summary] + scenario.warnings
                        + scenario.steps.map { $0.title + " " + ($0.detail ?? "") })
                .joined(separator: " ")
            #expect(text.localizedCaseInsensitiveContains("öğür"),
                    "\(id): öğürme/boğulma ayrımı yok")
        }
    }

    @Test func bothChokingScenariosCallEmergency() {
        for id in ["choking", "choking_toddler"] {
            let scenario = FirstAidCatalog.scenarios.first { $0.id == id }!
            #expect(scenario.callEmergency == true, "\(id): 112 çağrısı işaretli değil")
        }
    }

    @Test func chokingStepIdentifiersAreSequential() {
        for id in ["choking", "choking_toddler"] {
            let scenario = FirstAidCatalog.scenarios.first { $0.id == id }!
            #expect(scenario.steps.map(\.id) == Array(1...scenario.steps.count),
                    "\(id): adım numaraları sıralı değil")
        }
    }

    // MARK: - Alerji

    @Test func allergyScenarioMentionsEpinephrine() {
        // AAP acil planı: reçeteli adrenalin gecikmeden uygulanır.
        let allergy = FirstAidCatalog.scenarios.first { $0.id == "allergy" }!
        let text = (allergy.steps.map { $0.title + " " + ($0.detail ?? "") }
                    + allergy.warnings).joined(separator: " ")
        #expect(text.localizedCaseInsensitiveContains("adrenalin"))
    }

    @Test func allergyScenarioStillWarnsAgainstAntihistamineSubstitution() {
        let allergy = FirstAidCatalog.scenarios.first { $0.id == "allergy" }!
        let warnings = allergy.warnings.joined(separator: " ")
        #expect(warnings.localizedCaseInsensitiveContains("antihistamin"))
    }

    // MARK: - Semptom kategorisi

    @Test func allergicReactionCategoryExists() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }
        #expect(category != nil)
        #expect(category?.scenarios.isEmpty == false)
    }

    @Test func allergicReactionCategoryHasEmergencyLevel() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        let levels = Set(category.scenarios.map(\.urgency))
        #expect(levels.contains(.emergency))
    }

    @Test func anaphylaxisScenarioIsEmergency() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        let anaphylaxis = category.scenarios.first { $0.id == "allergy_anaphylaxis" }
        #expect(anaphylaxis != nil)
        #expect(anaphylaxis?.urgency == .emergency)
    }

    @Test func anaphylaxisAdviceMentionsEpinephrineAndEmergencyNumber() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        let anaphylaxis = category.scenarios.first { $0.id == "allergy_anaphylaxis" }!
        let text = ([anaphylaxis.advice] + anaphylaxis.nextSteps).joined(separator: " ")
        #expect(text.localizedCaseInsensitiveContains("adrenalin"))
        #expect(text.contains("112"))
    }

    @Test func everyAllergicScenarioHasNextSteps() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        for scenario in category.scenarios {
            #expect(!scenario.label.isEmpty, "\(scenario.id): etiket boş")
            #expect(!scenario.advice.isEmpty, "\(scenario.id): öneri boş")
            #expect(!scenario.nextSteps.isEmpty, "\(scenario.id): adım listesi boş")
        }
    }

    @Test func scenarioIdentifiersRemainUnique() {
        let firstAidIDs = FirstAidCatalog.scenarios.map(\.id)
        #expect(Set(firstAidIDs).count == firstAidIDs.count)
        let categoryIDs = SymptomCatalog.categories.map(\.id)
        #expect(Set(categoryIDs).count == categoryIDs.count)
    }
}
