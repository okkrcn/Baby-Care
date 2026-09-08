import Foundation

/// FDA "Big 9" major besin alerjenleri.
///
/// Tanıtım yaklaşımı güncel uluslararası konsensüse dayanır (ESPGHAN,
/// AAP 2023, EAACI 2021, NIAID): alerjenler geciktirilmez, tamamlayıcı
/// beslenmeyle birlikte yaklaşık 6. ayda ve hiçbir zaman 4 tamamlanmış
/// aydan önce olmamak üzere tanıtılır. Tolere edilen alerjen diyette
/// düzenli tutulur.
///
/// T.C. Sağlık Bakanlığı Türkiye Beslenme Rehberi (TÜBER 2022) yeni
/// besinler arasında 3–5 gün bırakılmasını önerir; uygulama bunu
/// isteğe bağlı gözlem aralığı olarak sunar, tanıtımı geciktirmez.
///
/// Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.
enum Allergen: String, CaseIterable, Codable, Sendable {
    case milk
    case egg
    case peanut
    case treeNut
    case wheat
    case soy
    case sesame
    case fish
    case shellfish

    var localizedTitle: String {
        switch self {
        case .milk:      return "Süt"
        case .egg:       return "Yumurta"
        case .peanut:    return "Yer fıstığı"
        case .treeNut:   return "Ağaç yemişleri"
        case .wheat:     return "Buğday"
        case .soy:       return "Soya"
        case .sesame:    return "Susam"
        case .fish:      return "Balık"
        case .shellfish: return "Kabuklu deniz ürünleri"
        }
    }

    var icon: String {
        switch self {
        case .milk:      return "drop.fill"
        case .egg:       return "oval.fill"
        case .peanut:    return "circle.grid.2x2.fill"
        case .treeNut:   return "leaf.circle.fill"
        case .wheat:     return "laurel.leading"
        case .soy:       return "circle.hexagongrid.fill"
        case .sesame:    return "circle.dotted"
        case .fish:      return "fish.fill"
        case .shellfish: return "water.waves"
        }
    }
}

struct AllergenInfo: Sendable {
    let minAgeMonths: Int
    /// Ne zaman ve nasıl tanıtılacağı.
    let introductionGuidance: String
    /// Boğulma riski yaratmayan sunum biçimi.
    let safeServingForm: String
    /// Erken tanıtımın koruyucu etkisine dair güçlü randomize kanıt var mı.
    let hasStrongEvidence: Bool
    let sourceURL: String
}

enum AllergenCatalog {
    static func info(for allergen: Allergen) -> AllergenInfo {
        switch allergen {
        case .egg:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda, 4 aydan önce olmamak üzere tanıtın. Tolere edilirse haftada birkaç kez vermeyi sürdürün — tek tadım koruyucu etki için yeterli değildir.",
                safeServingForm: "İyi pişmiş (haşlanmış veya çırpılmış) yumurtayı ezip küçük miktarla başlayın; gerekirse anne sütü veya püreyle inceltin. Çiğ ya da az pişmiş yumurta vermeyin.",
                hasStrongEvidence: true,
                sourceURL: "https://eaaci.org/guidelines-position-papers/eaaci-guideline-preventing-the-development-of-food-allergy-in-infants-and-young-children-2020-update/"
            )
        case .peanut:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda tanıtın. Bebeğinizde ağır egzama veya yumurta alerjisi varsa tanıtımdan önce çocuk hekimine danışın — bu durumda daha erken bir pencere ve öncesinde değerlendirme söz konusu olabilir.",
                safeServingForm: "Pürüzsüz fıstık ezmesini su, anne sütü, yoğurt veya tolere edilmiş bir püreyle akışkan olacak şekilde inceltin. Bütün fıstık veya kaşık dolusu koyu ezme boğulma tehlikesidir.",
                hasStrongEvidence: true,
                sourceURL: "https://www.niaid.nih.gov/sites/default/files/peanut-allergy-prevention-guidelines-clinician-summary.pdf"
            )
        case .milk:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yoğurt ve tuzsuz peynir 6. aydan itibaren verilebilir. İnek sütünün ana içecek olarak verilmesi 1 yaşı bekler — bu beslenme ve demir gerekçelidir, alerjen tanıtımının ertelenmesi değildir.",
                safeServingForm: "Pastörize sade yoğurt veya tuzsuz peynir, küçük miktarla.",
                hasStrongEvidence: false,
                sourceURL: "https://publications.aap.org/pediatrics/article/152/5/e2023062836/194356/Updates-in-Food-Allergy-Prevention-in-Children"
            )
        case .wheat:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda, ilk yıl içinde tanıtın; geciktirmeyin.",
                safeServingForm: "Buğdaylı bebek tahılı, iyi pişmiş yumuşak makarna veya yumuşatılmış ekmek.",
                hasStrongEvidence: false,
                sourceURL: "https://www.espghan.org/dam/jcr:ea5c9b57-9315-44b7-b9a0-149511b96654/ESPGHAN%20Infant%20Feeding%20Campaign%20-%20Guidance%20Summary.pdf"
            )
        case .soy:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda, ilk yıl içinde tanıtın.",
                safeServingForm: "İyi ezilmiş yumuşak tofu veya şekersiz soya yoğurdu.",
                hasStrongEvidence: false,
                sourceURL: "https://eaaci.org/guidelines-position-papers/eaaci-guideline-preventing-the-development-of-food-allergy-in-infants-and-young-children-2020-update/"
            )
        case .sesame:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda, ilk yıl içinde tanıtın. Susam 2023'ten beri dokuzuncu major alerjen olarak tanımlanır.",
                safeServingForm: "Tahini su, yoğurt veya tolere edilmiş bir püreyle inceltin. Koyu tahin ya da bütün susam tanesi vermeyin.",
                hasStrongEvidence: false,
                sourceURL: "https://www.fda.gov/food/buy-store-serve-safe-food/food-allergies-what-you-need-know"
            )
        case .fish:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda tanıtın. Bir balık türünü tolere etmek diğer türleri garanti etmez.",
                safeServingForm: "Tam pişmiş, bütün kılçıkları ayıklanmış, ezilmiş veya ince parçalanmış balık.",
                hasStrongEvidence: false,
                sourceURL: "https://www.nhs.uk/baby/weaning-and-feeding/food-allergies-in-babies-and-young-children/"
            )
        case .treeNut:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Badem, ceviz, fındık, kaju gibi yemişler ayrı ayrı tanıtılabilir; her biri farklı bir alerjendir. İlk yıl içinde geciktirmeyin.",
                safeServingForm: "Pürüzsüz yemiş ezmesini inceltin veya çok ince öğütülmüş tozunu püreye karıştırın. Bütün ve iri kıyılmış yemişler boğulma tehlikesidir; küçük çocuklara verilmez.",
                hasStrongEvidence: false,
                sourceURL: "https://www.healthychildren.org/English/healthy-living/nutrition/Pages/when-to-introduce-egg-peanut-butter-and-other-common-food-allergens-to-your-baby-food-allergy-prevention-tips.aspx"
            )
        case .shellfish:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda tanıtın. Kabuklu deniz ürünleri ile balık ayrı alerjen gruplarıdır.",
                safeServingForm: "Tam pişmiş, kabuğu ayrılmış, çok ince ezilmiş veya parçalanmış. Çiğ ya da az pişmiş vermeyin.",
                hasStrongEvidence: false,
                sourceURL: "https://www.nhs.uk/baby/weaning-and-feeding/food-allergies-in-babies-and-young-children/"
            )
        }
    }
}
