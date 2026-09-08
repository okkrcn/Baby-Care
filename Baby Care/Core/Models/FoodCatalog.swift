import Foundation

enum FoodGroup: String, CaseIterable, Sendable {
    case vegetable, fruit, grain, protein, dairy, legume, fat, other

    var localizedTitle: String {
        switch self {
        case .vegetable: return "Sebze"
        case .fruit:     return "Meyve"
        case .grain:     return "Tahıl"
        case .protein:   return "Protein"
        case .dairy:     return "Süt ürünü"
        case .legume:    return "Baklagil"
        case .fat:       return "Yağ"
        case .other:     return "Diğer"
        }
    }

    var icon: String {
        switch self {
        case .vegetable: return "carrot.fill"
        case .fruit:     return "apple.logo"
        case .grain:     return "laurel.leading"
        case .protein:   return "fork.knife"
        case .dairy:     return "drop.fill"
        case .legume:    return "circle.grid.3x3.fill"
        case .fat:       return "drop.triangle.fill"
        case .other:     return "questionmark.circle.fill"
        }
    }
}

enum ChokingRisk: String, Sendable {
    case low, medium, high

    var localizedTitle: String {
        switch self {
        case .low:    return "Düşük risk"
        case .medium: return "Dikkat"
        case .high:   return "Yüksek boğulma riski"
        }
    }
}

/// Yasak niteliğindeki yaş sınırı. `minAgeMonths`'tan farkı: o "bu yaştan
/// önce önerilmez", bu "bu yaştan önce verilmez" anlamına gelir ve
/// arayüzde daha ağır gösterilir.
struct AgeBarrier: Sendable {
    let minAgeMonths: Int
    let reason: String
    let sourceURL: String
}

struct FoodItem: Identifiable, Sendable {
    let id: String
    let name: String
    let group: FoodGroup
    let minAgeMonths: Int
    let prepPuree: String
    let prepFingerFood: String
    let prepFamilyMeal: String
    let chokingRisk: ChokingRisk
    let safePrepNote: String?
    let allergen: Allergen?
    let isIronRich: Bool
    let isVitaminCRich: Bool
    let ageBarrier: AgeBarrier?
}

/// Türk mutfağına uygun besin kütüphanesi.
///
/// Yaş önerileri ve yasaklar T.C. Sağlık Bakanlığı Türkiye Beslenme Rehberi
/// (TÜBER 2022) ile DSÖ 2023 tamamlayıcı beslenme kılavuzuna dayanır.
/// Alerjen tanıtımı için bkz. `AllergenCatalog`.
///
/// Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.
enum FoodCatalog {

    /// TÜBER 2022 — yaş bariyerlerinin ortak kaynağı.
    private static let tuberURL = "https://hsgm.saglik.gov.tr/depo/birimler/saglikli-beslenme-ve-hareketli-hayat-db/Dokumanlar/Rehberler/Turkiye_Beslenme_Rehber_TUBER_2022_min.pdf"

    static let all: [FoodItem] = [

        // MARK: - Sebzeler

        FoodItem(id: "zucchini", name: "Kabak", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Soyup küp küp doğrayın, buharda yumuşayana kadar pişirip ezin.",
                 prepFingerFood: "Parmak kalınlığında dilimleyip yumuşayana kadar buharda pişirin.",
                 prepFamilyMeal: "Zeytinyağlı kabak yemeğinden tuzsuz porsiyon ayırın.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "carrot", name: "Havuç (pişmiş)", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Soyup dilimleyin, iyice yumuşayana kadar haşlayıp ezin.",
                 prepFingerFood: "Parmak boyunda çubuklar hâlinde kesip yumuşayana kadar buharda pişirin.",
                 prepFamilyMeal: "Sebze yemeklerinde ince doğranmış olarak verin.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "raw_carrot", name: "Havuç (çiğ)", group: .vegetable, minAgeMonths: 12,
                 prepPuree: "Çiğ havuç püre için uygun değildir; pişirin.",
                 prepFingerFood: "Çiğ ve sert havuç boğulma tehlikesidir. İnce rendeleyerek verin.",
                 prepFamilyMeal: "Salatalarda ince rendelenmiş olarak; 3 yaşına kadar çubuk hâlinde vermeyin.",
                 chokingRisk: .high,
                 safePrepNote: "Çiğ havuç sert ve yuvarlaktır; soluk borusunu tam tıkayabilir. 3 yaşına kadar pişirin, rendeleyin veya ezin.",
                 allergen: nil, isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "potato", name: "Patates", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Haşlayıp soyun, birkaç damla anne sütüyle ezerek pürüzsüzleştirin.",
                 prepFingerFood: "Fırında yumuşak dilimler hâlinde pişirin.",
                 prepFamilyMeal: "Tuzsuz patates yemeği veya püresi olarak sofraya katın.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "sweet_potato", name: "Tatlı patates", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Fırınlayıp kabuğundan ayırın ve ezin.",
                 prepFingerFood: "Kalın dilimler hâlinde fırınlayın.",
                 prepFamilyMeal: "Sebze yemeklerinde doğranmış olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "broccoli", name: "Brokoli", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Buharda pişirip çatalla ezin.",
                 prepFingerFood: "Sapından tutulabilecek küçük buketler hâlinde buharda yumuşatın.",
                 prepFamilyMeal: "Zeytinyağlı olarak ince doğranmış verin.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "cauliflower", name: "Karnabahar", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Haşlayıp ezin; gaz yapabileceği için küçük miktarla başlayın.",
                 prepFingerFood: "Yumuşak buketler hâlinde buharda pişirin.",
                 prepFamilyMeal: "Sebze yemeği veya fırın karnabahar olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "spinach", name: "Ispanak", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "İyice yıkayıp haşlayın, sapları ayıklayıp ezin.",
                 prepFingerFood: "Yumuşak yaprakları ince kıyıp diğer besinlere karıştırın.",
                 prepFamilyMeal: "Zeytinyağlı ıspanak veya ıspanaklı yumurta olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: true, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "peas", name: "Bezelye", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Haşlayıp ezin; isterseniz kabuklarını süzgeçten geçirin.",
                 prepFingerFood: "İyice yumuşatıp hafifçe ezerek verin — bütün tane yuvarlaktır.",
                 prepFamilyMeal: "Sebze yemeklerinde ezilmiş olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Bütün bezelye tanesi yuvarlak ve kaygandır; küçük çocuklarda hafifçe ezerek verin.",
                 allergen: nil, isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "green_beans", name: "Taze fasulye", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Kılçıklarını alıp haşlayın ve ezin.",
                 prepFingerFood: "Yumuşayana kadar pişirip parmak boyunda kesin.",
                 prepFamilyMeal: "Zeytinyağlı taze fasulyeden tuzsuz porsiyon.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "tomato", name: "Domates", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Kabuğunu ve çekirdeklerini ayırıp ezin.",
                 prepFingerFood: "Kabuğu soyulmuş, çekirdeksiz dilimler hâlinde.",
                 prepFamilyMeal: "Yemeklerde rendelenmiş veya doğranmış olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "cherry_tomato", name: "Çeri domates", group: .vegetable, minAgeMonths: 9,
                 prepPuree: "Kabuğunu soyup ezin.",
                 prepFingerFood: "Bütün vermeyin; uzunlamasına dörde bölün.",
                 prepFamilyMeal: "Salatalarda dörde bölünmüş olarak; 4 yaşına kadar bütün vermeyin.",
                 chokingRisk: .high,
                 safePrepNote: "Bütün çeri domates soluk borusunu tam tıkayabilir. Daima uzunlamasına dörde bölün.",
                 allergen: nil, isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "pumpkin", name: "Balkabağı", group: .vegetable, minAgeMonths: 6,
                 prepPuree: "Fırınlayıp kabuğundan ayırarak ezin.",
                 prepFingerFood: "Yumuşak dilimler hâlinde fırınlayın.",
                 prepFamilyMeal: "Çorba veya sebze yemeği olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "leek", name: "Pırasa", group: .vegetable, minAgeMonths: 8,
                 prepPuree: "Beyaz kısmını iyice haşlayıp ezin.",
                 prepFingerFood: "Yumuşayana kadar pişirip ince kıyın — lifleri uzun olabilir.",
                 prepFamilyMeal: "Zeytinyağlı pırasadan ince doğranmış porsiyon.",
                 chokingRisk: .medium,
                 safePrepNote: "Pırasanın uzun lifleri yutmayı zorlaştırabilir; ince kıyarak verin.",
                 allergen: nil, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Meyveler

        FoodItem(id: "apple", name: "Elma", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Soyup haşlayın veya fırınlayın, ardından ezin.",
                 prepFingerFood: "Pişirerek yumuşatın veya ince rendeleyin. Çiğ ve sert elma vermeyin.",
                 prepFamilyMeal: "Rendelenmiş olarak yoğurda veya yulafa karıştırın.",
                 chokingRisk: .medium,
                 safePrepNote: "Çiğ elma parçaları sert ve yuvarlaktır. 3 yaşına kadar pişirin veya ince rendeleyin.",
                 allergen: nil, isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "pear", name: "Armut", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Olgun armudu soyup ezin; sert ise önce hafifçe pişirin.",
                 prepFingerFood: "Olgun ve yumuşak armuttan parmak dilimleri.",
                 prepFamilyMeal: "Doğranmış olarak meyve tabağında.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "banana", name: "Muz", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Olgun muzu çatalla ezin.",
                 prepFingerFood: "Uzunlamasına üçe bölüp kavranacak parça bırakın.",
                 prepFamilyMeal: "Dilimlenmiş olarak veya yoğurda karıştırılmış.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "avocado", name: "Avokado", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Olgun avokadoyu çatalla ezin.",
                 prepFingerFood: "Kalın dilimler hâlinde; kaygan olduğu için dış yüzeyini hafif toz yulafa bulayabilirsiniz.",
                 prepFamilyMeal: "Ezerek ekmeğe sürün veya salataya katın.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "peach", name: "Şeftali", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Kabuğunu soyup çekirdeğini çıkarın ve ezin.",
                 prepFingerFood: "Olgun şeftaliden kabuksuz dilimler.",
                 prepFamilyMeal: "Doğranmış olarak meyve tabağında.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "plum", name: "Erik", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Kabuğunu ve çekirdeğini ayırıp ezin.",
                 prepFingerFood: "Kabuksuz, çekirdeksiz dilimler hâlinde.",
                 prepFamilyMeal: "Doğranmış olarak; kabızlıkta yardımcı olabilir.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "apricot", name: "Kayısı", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Çekirdeğini çıkarıp ezin; kuru kayısıyı önce haşlayın.",
                 prepFingerFood: "Olgun kayısıdan kabuksuz dilimler.",
                 prepFamilyMeal: "Doğranmış olarak veya yoğurda karıştırılmış.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "strawberry", name: "Çilek", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Yıkayıp saplarını ayırın ve ezin.",
                 prepFingerFood: "Uzunlamasına dörde bölerek verin.",
                 prepFamilyMeal: "Doğranmış olarak meyve tabağında.",
                 chokingRisk: .medium,
                 safePrepNote: "Bütün çilek yuvarlaktır; uzunlamasına bölerek verin.",
                 allergen: nil, isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "watermelon", name: "Karpuz", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Çekirdeklerini ayıklayıp ezin.",
                 prepFingerFood: "Çekirdeksiz, parmak boyunda dilimler.",
                 prepFamilyMeal: "Doğranmış olarak; çekirdekleri mutlaka ayıklayın.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "melon", name: "Kavun", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Çekirdeklerini ayırıp ezin.",
                 prepFingerFood: "Parmak boyunda yumuşak dilimler.",
                 prepFamilyMeal: "Doğranmış olarak meyve tabağında.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "grape", name: "Üzüm", group: .fruit, minAgeMonths: 8,
                 prepPuree: "Kabuğunu soyup çekirdeklerini çıkardıktan sonra ezin.",
                 prepFingerFood: "Uzunlamasına dörde bölüp çekirdeklerini çıkararak verin.",
                 prepFamilyMeal: "4 yaşına kadar bütün vermeyin; uzunlamasına küçük parçalara ayırın.",
                 chokingRisk: .high,
                 safePrepNote: "Bütün üzüm soluk borusunu tam tıkayabilir ve boğulma vakalarının en sık nedenlerindendir. Daima uzunlamasına dörde bölün.",
                 allergen: nil, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "orange", name: "Portakal", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Zarlarını ayıklayıp ezin.",
                 prepFingerFood: "Zarı soyulmuş dilimler hâlinde.",
                 prepFamilyMeal: "Doğranmış olarak; suyunu değil kendisini tercih edin.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "mandarin", name: "Mandalina", group: .fruit, minAgeMonths: 6,
                 prepPuree: "Zarlarını ve çekirdeklerini ayıklayıp ezin.",
                 prepFingerFood: "Zarsız, çekirdeksiz dilimler.",
                 prepFamilyMeal: "Doğranmış olarak meyve tabağında.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true, ageBarrier: nil),

        FoodItem(id: "fig", name: "İncir", group: .fruit, minAgeMonths: 8,
                 prepPuree: "Taze incirin kabuğunu soyup ezin; kuru inciri önce haşlayın.",
                 prepFingerFood: "Kabuksuz, yumuşak dilimler.",
                 prepFamilyMeal: "Doğranmış olarak veya yoğurda karıştırılmış.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Tahıllar

        FoodItem(id: "rice", name: "Pirinç", group: .grain, minAgeMonths: 6,
                 prepPuree: "Bol suda iyice pişirip ezin veya pirinç unu muhallebisi yapın.",
                 prepFingerFood: "Yapışkan kıvamda pişirip küçük toplar hâlinde verin.",
                 prepFamilyMeal: "Tuzsuz pilav olarak sofraya katın.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "oat", name: "Yulaf", group: .grain, minAgeMonths: 6,
                 prepPuree: "Anne sütü, mama veya suyla lapa kıvamında pişirin.",
                 prepFingerFood: "Koyu kıvamda pişirip küçük parçalar hâlinde verin.",
                 prepFamilyMeal: "Yulaf ezmesi kahvaltısı olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "bulgur", name: "Bulgur", group: .grain, minAgeMonths: 8,
                 prepPuree: "İnce bulguru bol suda pişirip ezin.",
                 prepFingerFood: "Yumuşak pişmiş bulgurdan küçük köfteler.",
                 prepFamilyMeal: "Tuzsuz bulgur pilavı olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .wheat,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "pasta", name: "Makarna", group: .grain, minAgeMonths: 6,
                 prepPuree: "İyice pişirip ezin.",
                 prepFingerFood: "Büyük ve yumuşak şekilli makarnayı elle tutturun.",
                 prepFamilyMeal: "Tuzsuz sosla aile sofrasında.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .wheat,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "bread", name: "Ekmek", group: .grain, minAgeMonths: 6,
                 prepPuree: "Süt veya çorbayla ıslatıp ezin.",
                 prepFingerFood: "Hafif kızartılmış parmak dilimler — yumuşak taze ekmek ağızda topaklanabilir.",
                 prepFamilyMeal: "Sofrada dilimlenmiş olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Yumuşak taze ekmek ağızda top hâline gelebilir. Hafif kızartarak veya ıslatarak verin.",
                 allergen: .wheat, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "semolina", name: "İrmik", group: .grain, minAgeMonths: 6,
                 prepPuree: "Sütle veya suyla muhallebi kıvamında pişirin.",
                 prepFingerFood: "Koyu pişirip soğuduktan sonra küçük parçalar hâlinde.",
                 prepFamilyMeal: "İrmik helvası yerine şekersiz irmik lapası tercih edin.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .wheat,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "quinoa", name: "Kinoa", group: .grain, minAgeMonths: 6,
                 prepPuree: "İyice yıkayıp pişirin ve ezin.",
                 prepFingerFood: "Yapışkan kıvamda pişirip küçük toplar hâlinde.",
                 prepFamilyMeal: "Salata veya pilav yerine sofrada.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Protein

        FoodItem(id: "beef", name: "Kırmızı et (dana)", group: .protein, minAgeMonths: 6,
                 prepPuree: "Yağsız kısmı iyice haşlayıp kıyma hâline getirin ve suyuyla ezin.",
                 prepFingerFood: "Uzun ve yumuşak şeritler hâlinde pişirin; çocuk emerek suyunu alır.",
                 prepFamilyMeal: "Kıymalı sebze yemeklerinde tuzsuz porsiyon.",
                 chokingRisk: .medium,
                 safePrepNote: "Et küçük ve yumuşak hazırlanmalıdır; sert küpler boğulma riski taşır.",
                 allergen: nil, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "chicken", name: "Tavuk", group: .protein, minAgeMonths: 6,
                 prepPuree: "Haşlayıp didikleyin, suyuyla ezin.",
                 prepFingerFood: "Yumuşak but etinden şeritler hâlinde.",
                 prepFamilyMeal: "Tuzsuz tavuklu sebze yemeği olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Kuru göğüs eti ağızda dağılmaz; but etini tercih edin ve iyice yumuşatın.",
                 allergen: nil, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "turkey", name: "Hindi", group: .protein, minAgeMonths: 6,
                 prepPuree: "Haşlayıp didikleyin ve suyuyla ezin.",
                 prepFingerFood: "Yumuşak şeritler hâlinde pişirin.",
                 prepFamilyMeal: "Tuzsuz hindili yemeklerde.",
                 chokingRisk: .medium,
                 safePrepNote: "Kuru et ağızda dağılmaz; suyuyla birlikte ve yumuşak verin.",
                 allergen: nil, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "egg", name: "Yumurta (tam)", group: .protein, minAgeMonths: 6,
                 prepPuree: "İyi pişmiş yumurtayı ezip anne sütü veya püreyle inceltin.",
                 prepFingerFood: "İyi pişmiş omletten parmak şeritler.",
                 prepFamilyMeal: "Haşlanmış veya menemen olarak; her zaman tam pişmiş.",
                 chokingRisk: .low,
                 safePrepNote: nil, allergen: .egg,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "egg_yolk", name: "Yumurta sarısı", group: .protein, minAgeMonths: 6,
                 prepPuree: "İyi haşlanmış sarıyı ezip anne sütüyle inceltin; çeyrek sarı ile başlayın.",
                 prepFingerFood: "Tek başına parmak besin için uygun değildir; püreye karıştırın.",
                 prepFamilyMeal: "Haşlanmış yumurtanın sarısı olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .egg,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "fish_seabass", name: "Levrek", group: .protein, minAgeMonths: 6,
                 prepPuree: "Buharda pişirip tüm kılçıkları ayıklayın ve ezin.",
                 prepFingerFood: "Kılçıksız, yumuşak parçalar hâlinde.",
                 prepFamilyMeal: "Fırında balık olarak; kılçıkları mutlaka ayıklayın.",
                 chokingRisk: .medium,
                 safePrepNote: "Kılçıklar ciddi tehlikedir; her lokmayı elinizle kontrol edin.",
                 allergen: .fish, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "salmon", name: "Somon", group: .protein, minAgeMonths: 6,
                 prepPuree: "Buharda pişirip kılçıklarını ayıklayın ve ezin.",
                 prepFingerFood: "Kılçıksız, yumuşak parçalar hâlinde.",
                 prepFamilyMeal: "Fırında somon olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Kılçıkları tek tek kontrol edin.",
                 allergen: .fish, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "anchovy", name: "Hamsi", group: .protein, minAgeMonths: 8,
                 prepPuree: "Kılçığını çıkarıp pişirin ve ezin.",
                 prepFingerFood: "Kılçıksız fileto parçaları hâlinde.",
                 prepFamilyMeal: "Fırında hamsi olarak; kılçıksız verin.",
                 chokingRisk: .medium,
                 safePrepNote: "Hamsinin ince kılçıkları kolay gözden kaçar; fileto çıkarıp kontrol edin.",
                 allergen: .fish, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "shrimp", name: "Karides", group: .protein, minAgeMonths: 6,
                 prepPuree: "Tam pişirip kabuğunu ayırın ve çok ince ezin.",
                 prepFingerFood: "Tam pişmiş, kabuksuz, ince doğranmış olarak.",
                 prepFamilyMeal: "Tam pişmiş olarak; çiğ veya az pişmiş vermeyin.",
                 chokingRisk: .medium,
                 safePrepNote: "Karides lastik kıvamındadır; çok ince doğrayın.",
                 allergen: .shellfish, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "liver", name: "Ciğer", group: .protein, minAgeMonths: 6,
                 prepPuree: "İyice pişirip ezin; haftada 1–2 kez yeterlidir.",
                 prepFingerFood: "Yumuşak, küçük parçalar hâlinde.",
                 prepFamilyMeal: "Tuzsuz ciğer yemeği olarak; A vitamini yüksek olduğu için sık verilmez.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "tofu", name: "Tofu", group: .protein, minAgeMonths: 6,
                 prepPuree: "Yumuşak tofuyu çatalla ezin.",
                 prepFingerFood: "Parmak kalınlığında dilimler hâlinde.",
                 prepFamilyMeal: "Sebze yemeklerine katılmış olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .soy,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Süt ürünleri

        FoodItem(id: "yogurt", name: "Yoğurt", group: .dairy, minAgeMonths: 6,
                 prepPuree: "Sade, pastörize tam yağlı yoğurdu olduğu gibi verin.",
                 prepFingerFood: "Kaşıkla verilir; meyve püresiyle karıştırılabilir.",
                 prepFamilyMeal: "Yemek yanında sade yoğurt olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .milk,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "cheese_saltless", name: "Tuzsuz peynir", group: .dairy, minAgeMonths: 6,
                 prepPuree: "Çatalla ezip püreye karıştırın.",
                 prepFingerFood: "Küçük yumuşak küpler hâlinde.",
                 prepFamilyMeal: "Kahvaltıda tuzsuz beyaz peynir olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Sert peynir küpleri boğulma riski taşır; yumuşak ve küçük parçalar verin.",
                 allergen: .milk, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "kefir", name: "Kefir", group: .dairy, minAgeMonths: 8,
                 prepPuree: "Sade kefiri olduğu gibi kaşıkla verin.",
                 prepFingerFood: "İçecek olarak bardakla verilir.",
                 prepFamilyMeal: "Öğün yanında sade olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .milk,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "curd_cheese", name: "Lor peyniri", group: .dairy, minAgeMonths: 6,
                 prepPuree: "Çatalla ezip püreye karıştırın.",
                 prepFingerFood: "Kaşıkla verilir.",
                 prepFamilyMeal: "Kahvaltıda tuzsuz lor olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .milk,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Baklagiller

        FoodItem(id: "lentil_red", name: "Kırmızı mercimek", group: .legume, minAgeMonths: 6,
                 prepPuree: "İyice pişirip blenderdan geçirin veya süzgeçten ezin.",
                 prepFingerFood: "Koyu kıvamda köfte hâline getirin.",
                 prepFamilyMeal: "Tuzsuz mercimek çorbası olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "lentil_green", name: "Yeşil mercimek", group: .legume, minAgeMonths: 8,
                 prepPuree: "Uzun süre haşlayıp kabuklarını süzgeçten ayırın ve ezin.",
                 prepFingerFood: "İyice yumuşatıp hafifçe ezerek verin.",
                 prepFamilyMeal: "Tuzsuz mercimek yemeği olarak.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "chickpea", name: "Nohut", group: .legume, minAgeMonths: 8,
                 prepPuree: "Islatıp uzun süre haşlayın, kabuklarını ayırıp ezin.",
                 prepFingerFood: "İyice ezilmiş nohuttan köfteler veya humus.",
                 prepFamilyMeal: "Tuzsuz nohut yemeği olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Bütün nohut tanesi yuvarlaktır; ezerek verin.",
                 allergen: nil, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "white_beans", name: "Kuru fasulye", group: .legume, minAgeMonths: 8,
                 prepPuree: "Islatıp uzun süre haşlayın, kabuklarını ayırıp ezin.",
                 prepFingerFood: "İyice yumuşatıp ezerek verin.",
                 prepFamilyMeal: "Tuzsuz kuru fasulye olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Bütün tane yuvarlaktır; ezerek verin.",
                 allergen: nil, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "kidney_beans", name: "Barbunya", group: .legume, minAgeMonths: 8,
                 prepPuree: "İyice haşlayıp kabuklarını ayırarak ezin.",
                 prepFingerFood: "Ezilmiş olarak diğer besinlere karıştırın.",
                 prepFamilyMeal: "Tuzsuz barbunya yemeği olarak.",
                 chokingRisk: .medium,
                 safePrepNote: "Bütün tane yuvarlaktır; ezerek verin.",
                 allergen: nil, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Yağlar ve ezmeler

        FoodItem(id: "olive_oil", name: "Zeytinyağı", group: .fat, minAgeMonths: 6,
                 prepPuree: "Püreye birkaç damla ekleyerek enerji ve yağ asidi katkısı sağlayın.",
                 prepFingerFood: "Sebzeleri pişirirken kullanın.",
                 prepFamilyMeal: "Yemeklerde ve salatalarda.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "butter", name: "Tereyağı", group: .fat, minAgeMonths: 6,
                 prepPuree: "Püreye küçük bir parça ekleyin.",
                 prepFingerFood: "Ekmeğe ince sürülmüş olarak.",
                 prepFamilyMeal: "Yemeklerde az miktarda.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .milk,
                 isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "tahini", name: "Tahin", group: .fat, minAgeMonths: 6,
                 prepPuree: "Su, yoğurt veya tolere edilmiş bir püreyle akışkan olacak şekilde inceltin.",
                 prepFingerFood: "Ekmeğe çok ince sürülmüş olarak.",
                 prepFamilyMeal: "Pekmezsiz, ince sürülmüş olarak kahvaltıda.",
                 chokingRisk: .high,
                 safePrepNote: "Koyu tahin ağız damağına yapışıp soluk yolunu tıkayabilir. Daima inceltin, kaşık dolusu vermeyin.",
                 allergen: .sesame, isIronRich: true, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "peanut_butter", name: "Fıstık ezmesi", group: .fat, minAgeMonths: 6,
                 prepPuree: "Su, anne sütü, yoğurt veya püreyle akışkan olacak şekilde inceltin.",
                 prepFingerFood: "Ekmeğe çok ince sürülmüş olarak.",
                 prepFamilyMeal: "İnce sürülmüş olarak kahvaltıda.",
                 chokingRisk: .high,
                 safePrepNote: "Koyu fıstık ezmesi damağa yapışarak boğulmaya yol açabilir. Daima inceltin; bütün fıstık asla vermeyin.",
                 allergen: .peanut, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "almond_butter", name: "Badem ezmesi", group: .fat, minAgeMonths: 6,
                 prepPuree: "Pürüzsüz badem ezmesini suyla veya püreyle inceltin.",
                 prepFingerFood: "Ekmeğe çok ince sürülmüş olarak.",
                 prepFamilyMeal: "İnce sürülmüş olarak.",
                 chokingRisk: .high,
                 safePrepNote: "Koyu yemiş ezmesi damağa yapışır. Daima inceltin; bütün veya iri kıyılmış yemiş vermeyin.",
                 allergen: .treeNut, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        FoodItem(id: "whole_nut", name: "Bütün fındık ve kuruyemiş", group: .fat, minAgeMonths: 12,
                 prepPuree: "Çok ince öğütülmüş toz hâlinde püreye karıştırın.",
                 prepFingerFood: "Bütün veya iri kıyılmış hâlde asla verilmez.",
                 prepFamilyMeal: "3 yaşına kadar bütün verilmez; ezme veya ince toz olarak kullanın.",
                 chokingRisk: .high,
                 safePrepNote: "Bütün kuruyemiş küçük çocuklarda en sık boğulma nedenlerindendir. 3 yaşına kadar bütün vermeyin; ezme veya ince öğütülmüş toz kullanın.",
                 allergen: .treeNut, isIronRich: false, isVitaminCRich: false, ageBarrier: nil),

        // MARK: - Yaş bariyerli besinler

        FoodItem(id: "honey", name: "Bal", group: .other, minAgeMonths: 12,
                 prepPuree: "1 yaşından önce hiçbir biçimde verilmez.",
                 prepFingerFood: "1 yaşından önce hiçbir biçimde verilmez.",
                 prepFamilyMeal: "1 yaşından sonra az miktarda kullanılabilir.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false,
                 ageBarrier: AgeBarrier(
                    minAgeMonths: 12,
                    reason: "Bal, Clostridium botulinum sporları içerebilir; bebek bağırsağında toksin oluşarak infantil botulizme yol açabilir. Pişmiş ürüne katılması bu riski ortadan kaldırmaz.",
                    sourceURL: tuberURL)),

        FoodItem(id: "cow_milk_drink", name: "İnek sütü (içecek olarak)", group: .dairy, minAgeMonths: 12,
                 prepPuree: "1 yaşından önce ana içecek olarak verilmez; yemek hazırlamada az miktarda kullanılabilir.",
                 prepFingerFood: "İçecek olarak bardakla verilir.",
                 prepFamilyMeal: "1 yaşından sonra tam yağlı olarak günlük içecek şeklinde.",
                 chokingRisk: .low, safePrepNote: nil, allergen: .milk,
                 isIronRich: false, isVitaminCRich: false,
                 ageBarrier: AgeBarrier(
                    minAgeMonths: 12,
                    reason: "İnek sütünün proteini ve sodyumu yüksek, demir içeriği ve emilimi düşüktür. 1 yaşından önce ana içecek olarak verilmesi demir eksikliği riskini artırır. Yoğurt ve tuzsuz peynir 6. aydan itibaren verilebilir.",
                    sourceURL: tuberURL)),

        FoodItem(id: "salt", name: "Tuz", group: .other, minAgeMonths: 12,
                 prepPuree: "İlk yıl yemeğe tuz eklenmez.",
                 prepFingerFood: "İlk yıl yemeğe tuz eklenmez.",
                 prepFamilyMeal: "1 yaşından sonra da mümkün olduğunca az kullanılır.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false,
                 ageBarrier: AgeBarrier(
                    minAgeMonths: 12,
                    reason: "Bebeğin böbrekleri fazla sodyumu atmakta zorlanır. İlk yıl yemeğe tuz eklenmez; konserve, salamura, sucuk, salam ve sosis gibi yüksek tuzlu ürünler verilmez.",
                    sourceURL: tuberURL)),

        FoodItem(id: "added_sugar", name: "İlave şeker", group: .other, minAgeMonths: 24,
                 prepPuree: "İlk yıl şeker eklenmez.",
                 prepFingerFood: "İlk yıl şeker eklenmez.",
                 prepFamilyMeal: "2 yaşına kadar ilave şekerli yiyecek ve içeceklerden kaçınılır.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: false,
                 ageBarrier: AgeBarrier(
                    minAgeMonths: 24,
                    reason: "İlave şeker diş çürüğü ve tat alışkanlığı açısından risklidir. İki yaş altında ilave şekerli yiyecek ve içeceklerden kaçınılır; tatlandırma için meyvenin kendisi kullanılır.",
                    sourceURL: tuberURL)),

        FoodItem(id: "fruit_juice", name: "Meyve suyu", group: .other, minAgeMonths: 12,
                 prepPuree: "Meyve suyu yerine meyvenin kendisi veya püresi tercih edilir.",
                 prepFingerFood: "Meyvenin kendisi verilir.",
                 prepFamilyMeal: "1–3 yaş arası verilecekse yüzde 100 meyve suyu günde en fazla 120 ml ile sınırlandırılır.",
                 chokingRisk: .low, safePrepNote: nil, allergen: nil,
                 isIronRich: false, isVitaminCRich: true,
                 ageBarrier: AgeBarrier(
                    minAgeMonths: 12,
                    reason: "Meyve suyu lif içermez, şeker yoğunluğu yüksektir ve iştahı bozarak besleyici gıdaların yerini alabilir. Bir yaş altında önerilmez; 1–3 yaşta günde en fazla 120 ml.",
                    sourceURL: tuberURL))
    ]

    static func item(id: String) -> FoodItem? {
        all.first { $0.id == id }
    }

    /// Verilen yaşta gösterilebilecek besinler. Yaş bariyeri olanlar
    /// bariyer yaşına gelene kadar listede yer almaz.
    static func items(forAgeMonths months: Int) -> [FoodItem] {
        all.filter { item in
            guard item.minAgeMonths <= months else { return false }
            if let barrier = item.ageBarrier, months < barrier.minAgeMonths { return false }
            return true
        }
    }

    /// Türkçe karakterlere ve büyük/küçük harfe duyarsız arama.
    static func search(_ query: String) -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        let needle = fold(trimmed)
        return all.filter { fold($0.name).contains(needle) }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive],
                     locale: Locale(identifier: "tr_TR"))
    }
}
