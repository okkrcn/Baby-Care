import Testing
import Foundation
@testable import Baby_Care

struct FoodCatalogTests {

    @Test func catalogHasAtLeastSixtyItems() {
        #expect(FoodCatalog.all.count >= 60)
    }

    @Test func identifiersAreUnique() {
        let ids = FoodCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyItemHasAllThreeServingForms() {
        for item in FoodCatalog.all {
            #expect(!item.name.isEmpty, "\(item.id): ad boş")
            #expect(!item.prepPuree.isEmpty, "\(item.id): püre biçimi boş")
            #expect(!item.prepFingerFood.isEmpty, "\(item.id): parmak besin biçimi boş")
            #expect(!item.prepFamilyMeal.isEmpty, "\(item.id): aile yemeği biçimi boş")
        }
    }

    @Test func noItemIsRecommendedBeforeSixMonths() {
        for item in FoodCatalog.all {
            #expect(item.minAgeMonths >= 6, "\(item.id): 6 aydan önce önerilmiş")
        }
    }

    @Test func highChokingRiskItemsCarrySafePrepNote() {
        for item in FoodCatalog.all where item.chokingRisk == .high {
            #expect(item.safePrepNote?.isEmpty == false,
                    "\(item.id): yüksek boğulma riski ama hazırlama notu yok")
        }
    }

    @Test func honeyIsBarredBeforeTwelveMonths() {
        let honey = FoodCatalog.item(id: "honey")
        #expect(honey != nil)
        #expect(honey?.ageBarrier?.minAgeMonths == 12)
        #expect(honey?.ageBarrier?.reason.localizedCaseInsensitiveContains("botulizm") == true)
    }

    @Test func cowMilkAsDrinkIsBarredBeforeTwelveMonths() {
        #expect(FoodCatalog.item(id: "cow_milk_drink")?.ageBarrier?.minAgeMonths == 12)
    }

    @Test func saltIsBarredBeforeTwelveMonthsAndSugarBeforeTwentyFour() {
        #expect(FoodCatalog.item(id: "salt")?.ageBarrier?.minAgeMonths == 12)
        #expect(FoodCatalog.item(id: "added_sugar")?.ageBarrier?.minAgeMonths == 24)
    }

    @Test func fruitJuiceIsBarredBeforeTwelveMonths() {
        #expect(FoodCatalog.item(id: "fruit_juice")?.ageBarrier?.minAgeMonths == 12)
    }

    @Test func everyAgeBarrierHasSourceURL() {
        for item in FoodCatalog.all {
            if let barrier = item.ageBarrier {
                #expect(barrier.sourceURL.hasPrefix("https://"),
                        "\(item.id): yaş bariyerinde kaynak linki yok")
                #expect(!barrier.reason.isEmpty, "\(item.id): yaş bariyerinde gerekçe yok")
            }
        }
    }

    @Test func catalogContainsIronRichFoods() {
        // TÜBER 2022: 6. aydan itibaren demir kaynakları öncelikli.
        let ironRich = FoodCatalog.all.filter(\.isIronRich)
        #expect(ironRich.count >= 6)
        #expect(ironRich.contains { $0.id == "beef" })
    }

    @Test func allergenFlaggedFoodsResolveInAllergenCatalog() {
        for item in FoodCatalog.all {
            if let allergen = item.allergen {
                #expect(!AllergenCatalog.info(for: allergen).introductionGuidance.isEmpty,
                        "\(item.id): alerjen bilgisi çözülemedi")
            }
        }
    }

    @Test func everyMajorAllergenHasAtLeastOneFood() {
        // Alerjen panelinden besine geçebilmek için her alerjenin karşılığı olmalı.
        for allergen in Allergen.allCases {
            #expect(FoodCatalog.all.contains { $0.allergen == allergen },
                    "\(allergen): kütüphanede karşılık gelen besin yok")
        }
    }

    @Test func ageFilterExcludesFutureFoods() {
        let sixMonthItems = FoodCatalog.items(forAgeMonths: 6)
        #expect(sixMonthItems.allSatisfy { $0.minAgeMonths <= 6 })
        #expect(sixMonthItems.contains { $0.id == "beef" })
        // Bal 12 ay bariyerli — 6 aylık listede olmamalı
        #expect(!sixMonthItems.contains { $0.id == "honey" })
    }

    @Test func ageFilterIncludesBarredFoodsAfterBarrierAge() {
        let twelveMonthItems = FoodCatalog.items(forAgeMonths: 12)
        #expect(twelveMonthItems.contains { $0.id == "honey" })
        // İlave şeker 24 ay bariyerli — 12 aylık listede olmamalı
        #expect(!twelveMonthItems.contains { $0.id == "added_sugar" })
    }

    @Test func searchIsCaseAndDiacriticInsensitive() {
        #expect(FoodCatalog.search("YOĞURT").contains { $0.id == "yogurt" })
        #expect(FoodCatalog.search("yogurt").contains { $0.id == "yogurt" })
        #expect(FoodCatalog.search("Yoğ").contains { $0.id == "yogurt" })
    }

    @Test func emptySearchReturnsEverything() {
        #expect(FoodCatalog.search("").count == FoodCatalog.all.count)
        #expect(FoodCatalog.search("   ").count == FoodCatalog.all.count)
    }
}
