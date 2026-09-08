import Testing
import Foundation
@testable import Baby_Care

struct AllergenCatalogTests {

    @Test func nineMajorAllergensAreDefined() {
        #expect(Allergen.allCases.count == 9)
    }

    @Test func everyAllergenHasCompleteInfo() {
        for allergen in Allergen.allCases {
            let info = AllergenCatalog.info(for: allergen)
            #expect(!allergen.localizedTitle.isEmpty, "\(allergen): başlık boş")
            #expect(!allergen.icon.isEmpty, "\(allergen): ikon boş")
            #expect(!info.introductionGuidance.isEmpty, "\(allergen): tanıtım rehberi boş")
            #expect(!info.safeServingForm.isEmpty, "\(allergen): sunum biçimi boş")
            #expect(info.sourceURL.hasPrefix("https://"), "\(allergen): kaynak https değil")
        }
    }

    @Test func minimumIntroductionAgeIsNeverBelowFourMonths() {
        // Hiçbir kılavuz 4 tamamlanmış aydan önce tanıtım önermez.
        for allergen in Allergen.allCases {
            #expect(AllergenCatalog.info(for: allergen).minAgeMonths >= 4)
        }
    }

    @Test func peanutAndEggAreMarkedAsStrongEvidence() {
        // LEAP ve EAACI: erken tanıtımın koruyucu etkisi bu ikisinde güçlü.
        #expect(AllergenCatalog.info(for: .peanut).hasStrongEvidence == true)
        #expect(AllergenCatalog.info(for: .egg).hasStrongEvidence == true)
        #expect(AllergenCatalog.info(for: .shellfish).hasStrongEvidence == false)
    }

    @Test func chokingHazardsAreFlaggedForNutsAndSeeds() {
        // Bütün fındık ve koyu ezme boğulma tehlikesi — sunum notu bunu söylemeli.
        #expect(AllergenCatalog.info(for: .peanut).safeServingForm.contains("incelt"))
        #expect(AllergenCatalog.info(for: .treeNut).safeServingForm.contains("incelt"))
        #expect(AllergenCatalog.info(for: .sesame).safeServingForm.contains("incelt"))
    }

    @Test func rawValuesAreStableForPersistence() {
        // SwiftData'da rawValue saklanıyor; değişirse mevcut kayıtlar kopar.
        #expect(Allergen.milk.rawValue == "milk")
        #expect(Allergen.egg.rawValue == "egg")
        #expect(Allergen.peanut.rawValue == "peanut")
        #expect(Allergen.treeNut.rawValue == "treeNut")
        #expect(Allergen.wheat.rawValue == "wheat")
        #expect(Allergen.soy.rawValue == "soy")
        #expect(Allergen.sesame.rawValue == "sesame")
        #expect(Allergen.fish.rawValue == "fish")
        #expect(Allergen.shellfish.rawValue == "shellfish")
    }

    @Test func guidanceNeverTellsUserToRetryAfterReaction() {
        // Reaksiyon sonrası evde tekrar deneme önerisi tıbbi olarak yanlış olur.
        for allergen in Allergen.allCases {
            let info = AllergenCatalog.info(for: allergen)
            let text = info.introductionGuidance + " " + info.safeServingForm
            #expect(!text.localizedCaseInsensitiveContains("tekrar deneyin"),
                    "\(allergen): reaksiyon sonrası tekrar deneme önerisi var")
        }
    }
}
