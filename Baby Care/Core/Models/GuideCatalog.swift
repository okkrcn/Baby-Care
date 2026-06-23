import Foundation

/// Bebeğin yaşına göre gelişim rehberi. Aylık bantlar halinde içerik.
///
/// İçerik kaynakları: WHO Çocuk Büyüme Standartları, T.C. Sağlık Bakanlığı
/// pediatrik gelişim materyalleri, AAP (American Academy of Pediatrics) 0-6 ay
/// gelişim rehberleri. Bilgilendirme amaçlıdır; klinik karar için pediatristinize
/// danışın.
struct GuideStage: Identifiable, Hashable, Sendable {
    let id: String
    let minWeeks: Int
    let maxWeeks: Int
    let title: String              // "0–2 hafta"
    let summary: String            // kısa öz
    let grossMotor: [String]
    let fineMotor: [String]
    let language: [String]
    let socialEmotional: [String]
    let feedingTips: [String]
    let sleepTips: [String]
    let warningSigns: [String]     // hekime başvurma işaretleri
}

enum GuideCatalog {
    static let stages: [GuideStage] = [
        GuideStage(
            id: "stage_0_2w",
            minWeeks: 0, maxWeeks: 2,
            title: "0–2 hafta (Yenidoğan)",
            summary: "Bebek yeni ortamına uyum sağlıyor. Hemen hemen tüm hareketler refleks.",
            grossMotor: [
                "Yatarken başını yana çevirir.",
                "Kollar ve bacaklar bükük pozisyondadır.",
                "Kaldırıldığında baş sarkar — destek şarttır."
            ],
            fineMotor: [
                "Eller genelde yumruktur.",
                "Avuca konulan parmağı sıkıca kavrar (kavrama refleksi)."
            ],
            language: [
                "Tek ses olarak ağlama vardır.",
                "Ani yüksek seslere irkilerek tepki verir (Moro refleksi)."
            ],
            socialEmotional: [
                "Yüze 20–25 cm mesafeden odaklanabilir.",
                "Tanıdık seslere yönelir."
            ],
            feedingTips: [
                "İlk haftalarda her öğünde 60 ml'ye kadar beslenme normaldir.",
                "Günde 8–12 kez emzirme. Bebek istediğinde besleme önerilir.",
                "Doğumdan sonraki ilk 2–3 günde %10'a kadar kilo kaybı normaldir; 2 haftada doğum kilosuna dönmesi beklenir."
            ],
            sleepTips: [
                "Günde 16–18 saat uyku, çoğu 2–4 saatlik aralıklarla.",
                "Sırtüstü uyutun; yatakta yumuşak nesne bulundurmayın."
            ],
            warningSigns: [
                "Beslenmeyi reddetme veya emerken halsizlik",
                "Sarı renkli cilt/göz akı belirginleşmesi",
                "37.5 °C üzeri ateş — yenidoğanda acil değerlendirilmeli",
                "İdrar çıkışı azlığı (günde 6'dan az ıslak bez)"
            ]
        ),

        GuideStage(
            id: "stage_2_6w",
            minWeeks: 2, maxWeeks: 6,
            title: "2–6 hafta (1 ay civarı)",
            summary: "Refleksler hâlâ baskın; başını kısa süreliğine kaldırabilir.",
            grossMotor: [
                "Yüzükoyunken başını kısa süreli kaldırabilir.",
                "Hareketler hâlâ büyük ölçüde refleks tabanlıdır."
            ],
            fineMotor: [
                "Eller yumruk; ara sıra açılır.",
                "Kavrama refleksi sürer."
            ],
            language: [
                "Farklı amaçlar için farklı ağlamalar (açlık, uyku, rahatsızlık).",
                "Boğaz seslerini çıkarmaya başlar."
            ],
            socialEmotional: [
                "Hareketli nesneleri kısa süre takip eder.",
                "Sosyal gülümseme henüz başlamamış olabilir."
            ],
            feedingTips: [
                "Her öğünde ~90 ml; günde 6–10 emzirme tipiktir.",
                "Mide kapasitesi 125–150 ml'ye doğru artar.",
                "Her emzirmeden sonra gaz çıkarmaya yardım edin."
            ],
            sleepTips: [
                "Gece ile gündüz ayrımı henüz oluşmamıştır.",
                "Banyo + emzirme + ışık azaltma rutini denemeye başlanabilir."
            ],
            warningSigns: [
                "Beslenmeden sonra fışkırır tarzda kusma",
                "Cilt rengi solgun veya morarmış",
                "Aşırı uyuklama, uyandırılamama",
                "Doğum kilosunu 2 haftada geri kazanamamış olma"
            ]
        ),

        GuideStage(
            id: "stage_6_12w",
            minWeeks: 6, maxWeeks: 12,
            title: "6–12 hafta (2–3 ay)",
            summary: "Sosyal gülümseme görülür. Başını daha iyi tutar.",
            grossMotor: [
                "Yüzükoyunken başını 45° kaldırabilir.",
                "Bacaklarını esnetip uzatır."
            ],
            fineMotor: [
                "Ellerini açar, parmaklarını birleştirir.",
                "Çıngırağı eline alabilir."
            ],
            language: [
                "Çağıltı sesleri (cooing) başlar.",
                "Konuştuğunuzda yüzünüze odaklanır."
            ],
            socialEmotional: [
                "Sosyal gülümseme görülür (6 haftadan itibaren).",
                "Sevdiği sesleri tanır."
            ],
            feedingTips: [
                "Mide kapasitesi ~150–180 ml; günde 4–8 emzirme.",
                "Sadece anne sütü/mama; ek gıda henüz yok."
            ],
            sleepTips: [
                "Toplam ~14–16 saat uyku; gece uykuları 4–5 saate çıkabilir.",
                "Uykuya dalmadan yatağa bırakma rutini denenebilir."
            ],
            warningSigns: [
                "Hâlâ hiç gülümsememe (3. ay sonu)",
                "Yüksek seslere yanıt vermeme",
                "Başını hiç kaldıramama",
                "Tek tarafa belirgin yatkınlık (tortikolis şüphesi)"
            ]
        ),

        GuideStage(
            id: "stage_12_18w",
            minWeeks: 12, maxWeeks: 18,
            title: "12–18 hafta (3–4 ay)",
            summary: "Ellerini keşfeder, sırtüstünden yana dönmeye başlar.",
            grossMotor: [
                "Yüzükoyunken başını 90° kaldırır, kollarına yaslanır.",
                "Sırtüstünden yana dönmeye başlar."
            ],
            fineMotor: [
                "Ellerini ağzına götürür, kendini keşfeder.",
                "Önündeki oyuncağa uzanır."
            ],
            language: [
                "Heceler oluşturmaya başlar ('agu', 'göö').",
                "Yüksek sesle güler."
            ],
            socialEmotional: [
                "Tanıdık yüzlere geniş gülümser.",
                "Aynaya ilgi gösterir."
            ],
            feedingTips: [
                "Ana besin hâlâ anne sütü/mama.",
                "Bazı bebekler beslenme aralıklarını uzatabilir."
            ],
            sleepTips: [
                "Günde 14–15 saat; geceleri 6–8 saat uyuyabilir.",
                "'4 ay uyku regresyonu' bu dönemde görülebilir — geçicidir."
            ],
            warningSigns: [
                "Gülmeme veya ses çıkarmama",
                "Eline tutuşturulan nesneyi tutamama",
                "Aşırı katı (hipertonik) veya gevşek (hipotonik) kaslar",
                "Asimetrik hareket (bir tarafı diğerinden belirgin az)"
            ]
        ),

        GuideStage(
            id: "stage_18_22w",
            minWeeks: 18, maxWeeks: 22,
            title: "18–22 hafta (4–5 ay)",
            summary: "Yana dönüşler artar, nesneleri amaçlı tutar.",
            grossMotor: [
                "Sırtüstünden yüzükoyuna döner.",
                "Kollarından destekleyerek oturma denemeleri yapar."
            ],
            fineMotor: [
                "Nesneleri kavrar ve ağzına götürür.",
                "İki elini ortada birleştirir."
            ],
            language: [
                "Sesleri taklit etmeye çalışır.",
                "Adını söylediğinizde bakar."
            ],
            socialEmotional: [
                "Yabancılarla tanıdıklar arasında ayrım yapar.",
                "Oyuncağa ulaşmak için kollar uzanır."
            ],
            feedingTips: [
                "Ek gıdaya 6. ayda geçilir; şimdilik sadece süt.",
                "Bazı bebekler suyu merak edebilir — 6. aydan önce verilmesi önerilmez."
            ],
            sleepTips: [
                "Gündüz şekerlemeleri 3'e iner; her biri 1–2 saat.",
                "Gece uykusu çoğunlukla 8–10 saat (bölünmeli olabilir)."
            ],
            warningSigns: [
                "Nesnelere uzanmama, kavramama",
                "Yana dönmenin hiç olmaması",
                "Göz teması kuramama"
            ]
        ),

        GuideStage(
            id: "stage_22_26w",
            minWeeks: 22, maxWeeks: 26,
            title: "22–26 hafta (5–6 ay)",
            summary: "Destekle oturur, eli ağzına götürür, sesli iletişim kurar.",
            grossMotor: [
                "Destekle veya kısa süre desteksiz oturabilir.",
                "Her iki yöne döner."
            ],
            fineMotor: [
                "Oyuncağı bir elden diğerine geçirebilir.",
                "Ağzına götürerek inceler."
            ],
            language: [
                "Tekrarlı heceler ('ba-ba', 'da-da') başlar — anlamı yoktur.",
                "Ses tonunda duygu yansır (mutluluk/üzüntü)."
            ],
            socialEmotional: [
                "Aile bireylerini tanır, ayna görüntüsüne gülümser.",
                "Adıyla seslenildiğinde dönmeye başlar."
            ],
            feedingTips: [
                "6. ayın sonunda ek gıdaya geçiş başlar (DSÖ önerisi).",
                "Demir içeren püreler (et, yumurta sarısı) ile başlanabilir.",
                "İnek/keçi sütü 1 yaşa kadar verilmez."
            ],
            sleepTips: [
                "Toplam ~12–14 saat uyku; çoğu geceleri."
            ],
            warningSigns: [
                "Hiç ses çıkarmama, hiç gülmeme",
                "Destekle bile oturamama",
                "Aynı seviyede iki elini birleştirememe"
            ]
        ),

        GuideStage(
            id: "stage_26_plus",
            minWeeks: 26, maxWeeks: Int.max,
            title: "26+ hafta (6 ay sonrası)",
            summary: "Uygulamanın hedef kapsamı dışında; doktor takibi devam etmeli.",
            grossMotor: ["Bu uygulamanın 0–6 ay odağı dışında. Pediatristinize başvurun."],
            fineMotor: [],
            language: [],
            socialEmotional: [],
            feedingTips: [
                "Ek gıdaya tam geçiş süreci başlar.",
                "Anne sütü 2 yaşına kadar destekleyici olabilir (DSÖ)."
            ],
            sleepTips: [],
            warningSigns: [
                "Gelişim mihenk taşlarında belirgin gecikme",
                "Edinilmiş becerilerin kaybı"
            ]
        )
    ]

    /// Bebeğin yaşına (haftalık) göre uygun gelişim aşamasını döner.
    static func stage(forAgeWeeks weeks: Int) -> GuideStage {
        stages.first { weeks >= $0.minWeeks && weeks < $0.maxWeeks } ?? stages.last!
    }
}
