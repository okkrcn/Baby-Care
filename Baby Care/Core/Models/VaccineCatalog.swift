import Foundation

/// Bir aşının statik tanımı (uygulamayla birlikte gelen sabit veri).
/// Kullanıcının bebeğine atanmış kayıt için `VaccinationRecord` kullanılır.
struct VaccineDefinition: Identifiable, Hashable, Sendable {
    let id: String                  // ör: "hexa_2m"
    let shortName: String           // ör: "Altılı Karma 1. doz"
    let fullName: String            // ör: "DaBT-İPA-Hib-HepB 1. doz"
    let scheduledAgeMonths: Int     // doğumdan kaç ay sonra
    let scheduledAgeDays: Int       // 0 = ay sonunda; özel günler için
    let description: String         // kullanıcıya gösterilecek metin
    let route: String               // uygulama yolu (kas içi, oral, vs.)
    let isOptional: Bool            // takvim dışı isteğe bağlı mı
}

/// T.C. Sağlık Bakanlığı Genişletilmiş Bağışıklama Programı 2026 — 0-6 ay.
/// Nisan 2025 itibarıyla altılı karma (DaBT-İPA-Hib-HepB) uygulamadadır.
///
/// Kaynak: T.C. Sağlık Bakanlığı Aşı Portalı (asi.saglik.gov.tr).
/// Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.
enum VaccineCatalog {
    static let firstSixMonths: [VaccineDefinition] = [
        VaccineDefinition(
            id: "hepb_birth",
            shortName: "Hepatit B (1. doz)",
            fullName: "Hepatit B — Doğum dozu",
            scheduledAgeMonths: 0,
            scheduledAgeDays: 0,
            description: "Doğum sonrası ilk dozdur. Altılı karma içinde devam dozları yer aldığı için ek doz yapılmaz.",
            route: "Kas içi (uyluk)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "bcg_2m",
            shortName: "BCG (Verem)",
            fullName: "BCG — Tüberküloz",
            scheduledAgeMonths: 2,
            scheduledAgeDays: 0,
            description: "Tüberküloza karşı koruma sağlar. Sol omuza intradermal uygulanır.",
            route: "Cilt içi (sol omuz)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "hexa_2m",
            shortName: "Altılı Karma 1. doz",
            fullName: "DaBT-İPA-Hib-HepB 1. doz",
            scheduledAgeMonths: 2,
            scheduledAgeDays: 0,
            description: "Difteri, boğmaca, tetanoz, çocuk felci, Hib ve Hepatit B'ye karşı tek enjeksiyonla koruma.",
            route: "Kas içi (uyluk)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "kpa_2m",
            shortName: "KPA 1. doz",
            fullName: "Konjuge Pnömokok Aşısı (KPA) 1. doz",
            scheduledAgeMonths: 2,
            scheduledAgeDays: 0,
            description: "Pnömokok bakterisine karşı bağışıklık sağlar; menenjit ve zatürreden korur.",
            route: "Kas içi",
            isOptional: false
        ),
        VaccineDefinition(
            id: "hexa_4m",
            shortName: "Altılı Karma 2. doz",
            fullName: "DaBT-İPA-Hib-HepB 2. doz",
            scheduledAgeMonths: 4,
            scheduledAgeDays: 0,
            description: "Altılı karmanın ikinci dozu.",
            route: "Kas içi (uyluk)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "kpa_4m",
            shortName: "KPA 2. doz",
            fullName: "Konjuge Pnömokok Aşısı (KPA) 2. doz",
            scheduledAgeMonths: 4,
            scheduledAgeDays: 0,
            description: "KPA'nın ikinci dozu.",
            route: "Kas içi",
            isOptional: false
        ),
        VaccineDefinition(
            id: "hexa_6m",
            shortName: "Altılı Karma 3. doz",
            fullName: "DaBT-İPA-Hib-HepB 3. doz",
            scheduledAgeMonths: 6,
            scheduledAgeDays: 0,
            description: "Altılı karmanın üçüncü dozu.",
            route: "Kas içi (uyluk)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "kpa_6m",
            shortName: "KPA 3. doz",
            fullName: "Konjuge Pnömokok Aşısı (KPA) 3. doz",
            scheduledAgeMonths: 6,
            scheduledAgeDays: 0,
            description: "KPA'nın üçüncü dozu.",
            route: "Kas içi",
            isOptional: false
        ),
        VaccineDefinition(
            id: "opa_6m",
            shortName: "OPA 1. doz",
            fullName: "Oral Polio Aşısı (OPA) 1. doz",
            scheduledAgeMonths: 6,
            scheduledAgeDays: 0,
            description: "Çocuk felcine karşı ağızdan damla şeklinde verilir.",
            route: "Ağızdan (oral)",
            isOptional: false
        )
    ]

    static func definition(forID id: String) -> VaccineDefinition? {
        firstSixMonths.first { $0.id == id }
    }
}
