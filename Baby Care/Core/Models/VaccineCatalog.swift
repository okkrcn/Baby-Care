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
    /// Takvimden çıkarılmış tanım. Yeni kayıt üretilmez, ama mevcut
    /// kullanıcı kayıtlarının adı çözümlenebilsin diye katalogda kalır.
    var isRetired: Bool = false
}

/// T.C. Sağlık Bakanlığı Genişletilmiş Bağışıklama Programı — 0-24 ay.
/// Nisan 2025 itibarıyla altılı karma (DaBT-İPA-Hib-HepB) uygulamadadır.
///
/// Kaynak: Ulusal Çocukluk Dönemi Aşılama Takvimi (2025),
/// https://asi.saglik.gov.tr/depo/2025/asi_takvimi/asi_takvimi_2025.pdf
///
/// Kapsam dışı (24 ay üstü): 48. ayda KKK 2. doz, DaBT-İPA rapel ve
/// suçiçeği 2. dozu; 13 yaşta Td rapel.
///
/// Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.
enum VaccineCatalog {
    static let schedule: [VaccineDefinition] = [
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
            id: "opa_6m",
            shortName: "OPA 1. doz",
            fullName: "Oral Polio Aşısı (OPA) 1. doz",
            scheduledAgeMonths: 6,
            scheduledAgeDays: 0,
            description: "Çocuk felcine karşı ağızdan damla şeklinde verilir.",
            route: "Ağızdan (oral)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "mmr_9m",
            shortName: "KKK Ek Doz",
            fullName: "Kızamık-Kızamıkçık-Kabakulak — Ek doz",
            scheduledAgeMonths: 9,
            scheduledAgeDays: 0,
            description: "Kızamığa karşı erken koruma sağlamak için takvime eklenen ek dozdur. 12. aydaki 1. dozun yerine geçmez.",
            route: "Cilt altı",
            isOptional: false
        ),
        VaccineDefinition(
            id: "mmr_12m",
            shortName: "KKK 1. doz",
            fullName: "Kızamık-Kızamıkçık-Kabakulak 1. doz",
            scheduledAgeMonths: 12,
            scheduledAgeDays: 0,
            description: "Kızamık, kızamıkçık ve kabakulağa karşı ilk tam dozdur.",
            route: "Cilt altı",
            isOptional: false
        ),
        VaccineDefinition(
            id: "varicella_12m",
            shortName: "Suçiçeği 1. doz",
            fullName: "Suçiçeği (Varisella) 1. doz",
            scheduledAgeMonths: 12,
            scheduledAgeDays: 0,
            description: "Suçiçeğine karşı koruma sağlar. İkinci doz 48. ayda uygulanır.",
            route: "Cilt altı",
            isOptional: false
        ),
        VaccineDefinition(
            id: "kpa_12m",
            shortName: "KPA Pekiştirme",
            fullName: "Konjuge Pnömokok Aşısı (KPA) — Pekiştirme dozu",
            scheduledAgeMonths: 12,
            scheduledAgeDays: 0,
            description: "KPA şemasının pekiştirme dozudur. Türkiye'de KPA 2., 4. ay ve 12. ay olmak üzere 2+1 şeklinde uygulanır.",
            route: "Kas içi",
            isOptional: false
        ),
        VaccineDefinition(
            id: "hexa_18m",
            shortName: "Altılı Karma Pekiştirme",
            fullName: "DaBT-İPA-Hib-HepB — Pekiştirme dozu",
            scheduledAgeMonths: 18,
            scheduledAgeDays: 0,
            description: "Altılı karmanın pekiştirme dozudur.",
            route: "Kas içi (uyluk)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "opa_18m",
            shortName: "OPA 2. doz",
            fullName: "Oral Polio Aşısı (OPA) 2. doz",
            scheduledAgeMonths: 18,
            scheduledAgeDays: 0,
            description: "Çocuk felcine karşı ikinci ağızdan doz.",
            route: "Ağızdan (oral)",
            isOptional: false
        ),
        VaccineDefinition(
            id: "hepa_18m",
            shortName: "Hepatit A 1. doz",
            fullName: "Hepatit A 1. doz",
            scheduledAgeMonths: 18,
            scheduledAgeDays: 0,
            description: "Hepatit A virüsüne karşı ilk dozdur; ikinci doz 24. ayda uygulanır.",
            route: "Kas içi",
            isOptional: false
        ),
        VaccineDefinition(
            id: "hepa_24m",
            shortName: "Hepatit A 2. doz",
            fullName: "Hepatit A 2. doz",
            scheduledAgeMonths: 24,
            scheduledAgeDays: 0,
            description: "Hepatit A aşısının ikinci ve son dozudur.",
            route: "Kas içi",
            isOptional: false
        ),

        // MARK: - Takvimden çıkarılmış tanımlar
        // Yeni kayıt üretilmez; mevcut kullanıcı kayıtları ad çözebilsin diye kalır.

        VaccineDefinition(
            id: "kpa_6m",
            shortName: "KPA 3. doz",
            fullName: "Konjuge Pnömokok Aşısı (KPA) 3. doz",
            scheduledAgeMonths: 6,
            scheduledAgeDays: 0,
            description: "Bu doz güncel ulusal takvimde yer almıyor. Türkiye'de KPA şeması 2., 4. ay ve 12. ay pekiştirme dozu şeklindedir.",
            route: "Kas içi",
            isOptional: false,
            isRetired: true
        )
    ]

    /// Yeni bebek için takvim üretirken kullanılan liste — emekli tanımlar hariç.
    static var scheduled: [VaccineDefinition] {
        schedule.filter { !$0.isRetired }
    }

    static func definition(forID id: String) -> VaccineDefinition? {
        schedule.first { $0.id == id }
    }
}
