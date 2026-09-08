import Foundation

/// Bebeğin yaşına göre gelişim rehberi. Aylık bantlar halinde içerik — 0-24 ay.
///
/// İçerik kaynakları: WHO Çocuk Büyüme Standartları, T.C. Sağlık Bakanlığı
/// pediatrik gelişim materyalleri, AAP (American Academy of Pediatrics) gelişim
/// rehberleri, CDC 'Learn the Signs. Act Early' 2022 mihenk taşları, TÜBER 2022
/// tamamlayıcı beslenme önerileri ve AASM uyku süresi önerileri. Bilgilendirme amaçlıdır; klinik karar için pediatristinize
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
            id: "stage_6_8m",
            minWeeks: 26, maxWeeks: 35,
            title: "6–8 ay (Ek gıdaya geçiş)",
            summary: "Tamamlayıcı beslenme başlar. Anne sütü ana besin olmayı sürdürür.",
            grossMotor: [
                "Desteksiz oturur, oturma pozisyonuna kendi geçebilir.",
                "Emeklemeye başlar.",
                "Tutunarak ayağa kalkmayı deneyebilir."
            ],
            fineMotor: [
                "Oyuncağı bir elinden diğerine geçirir.",
                "Yiyeceği parmaklarıyla kendine doğru tırmıklar.",
                "İki nesneyi birbirine vurur."
            ],
            language: [
                "Tekrarlı heceler artar ('ba-ba-ba', 'ma-ma-ma').",
                "Adı söylendiğinde bakar.",
                "'Hayır' dendiğinde kısa süre duraklar."
            ],
            socialEmotional: [
                "Yabancı kaygısı başlayabilir; tanıdıklara yapışır.",
                "Farklı yüz ifadeleri gösterir: mutlu, üzgün, kızgın.",
                "'Ce-ee' oyunlarında güler."
            ],
            feedingTips: [
                "Ek gıda 6. ay dolunca (180. gün) başlar; 2–3 ana öğün, iştaha göre 1–2 ara öğün.",
                "2–3 tatlı kaşığıyla başlanır, kademeli olarak öğün başına yaklaşık 125 ml'ye çıkılır.",
                "Demir açısından zengin besinler önceliklidir: kırmızı et, tavuk, balık, yumurta.",
                "Bitkisel demirin emilimi için C vitamini içeren sebze veya meyveyle birlikte verin.",
                "Alerjen besinler geciktirilmez; yumurta ve yer fıstığı bu dönemde tanıtılabilir.",
                "Bal 1 yaşından önce verilmez — infantil botulizm riski taşır.",
                "Yemeğe tuz ve şeker eklenmez.",
                "8. ay dolaylarında yumuşak parmak besinlere geçilebilir."
            ],
            sleepTips: [
                "Toplam 12–16 saat; genellikle 2 gündüz uykusu.",
                "Gece uyanmaları diş çıkarma veya ayrılık kaygısıyla artabilir."
            ],
            warningSigns: [
                "Destekle bile oturamama",
                "Bacaklarına ağırlık verememe",
                "Babıldamama, 'mama/baba' benzeri sesler çıkarmama",
                "Adı söylendiğinde bakmama",
                "Katı gıdayı ağzında tutamama veya sürekli püskürtme",
                "Kilo alımının durması"
            ]
        ),

        GuideStage(
            id: "stage_9_11m",
            minWeeks: 35, maxWeeks: 52,
            title: "9–11 ay",
            summary: "Hareket alanı genişler; kendi kendine beslenme becerileri gelişir.",
            grossMotor: [
                "Tutunarak ayağa kalkar ve mobilyalara tutunarak yürür.",
                "Oturma ve ayağa kalkma arasında geçiş yapar.",
                "Bazı bebekler birkaç bağımsız adım atmaya başlar."
            ],
            fineMotor: [
                "Başparmak ve işaret parmağıyla küçük yiyecekleri alır (çimdik kavraması).",
                "Nesneyi kabın içine koyar.",
                "Parmaklarıyla kendini beslemeye başlar."
            ],
            language: [
                "'Mama', 'dada' gibi ilk anlamlı kelimeler görülebilir.",
                "'Bay bay' yapar.",
                "Basit yönergeleri ve 'hayır'ı anlamaya başlar."
            ],
            socialEmotional: [
                "Ayrılık kaygısı belirginleşir.",
                "İlgi çekmek veya yardım istemek için yetişkine bakar.",
                "Alkış ve 'ce-ee' gibi sosyal oyunlar oynar."
            ],
            feedingTips: [
                "3–4 ana öğün ve iştaha göre 1–2 ara öğün; öğün başına yaklaşık 125 ml.",
                "Ek gıdadan beklenen enerji günde yaklaşık 300 kcal.",
                "Kıvam ince doğranmış ve elle kavranabilir hâle gelir — her şeyi blenderdan geçirmeyin.",
                "7–8. aylardan itibaren ezilmiş mercimek, nohut ve fasulye eklenebilir.",
                "Yemeğe tuz ve şeker eklenmez; inek sütü ana içecek olarak verilmez.",
                "Çocuk yerken oturmalı ve daima gözetim altında olmalıdır."
            ],
            sleepTips: [
                "Toplam 12–16 saat; iki gündüz uykusundan tek uykuya geçiş başlayabilir.",
                "Yeni kazanılan hareket becerileri geceleri uyanmaya yol açabilir."
            ],
            warningSigns: [
                "Tutunarak ayağa kalkamama",
                "Hiçbir jest kullanmama (el sallamama, işaret etmeme)",
                "Anlamlı hiçbir kelime denememe",
                "Saklanan nesneyi aramama",
                "Kazanılmış bir becerinin kaybı"
            ]
        ),

        GuideStage(
            id: "stage_12_15m",
            minWeeks: 52, maxWeeks: 65,
            title: "12–15 ay",
            summary: "Yürüme başlar. Beslenme aile sofrasına yaklaşır, inek sütü artık verilebilir.",
            grossMotor: [
                "Kendi başına birkaç adım atar; yürüyüş henüz dengesiz olabilir.",
                "Ayağa kalkıp tekrar oturabilir.",
                "Yürürken oyuncak taşıyabilir."
            ],
            fineMotor: [
                "Parmaklarıyla kendini besler, kaşığı denemeye başlar.",
                "Birkaç nesneyi üst üste koymayı dener.",
                "Kalemle karalama yapmayı deneyebilir."
            ],
            language: [
                "'Mama' ve 'dada' dışında bir–iki kelime söylemeyi dener.",
                "İstek veya yardım için işaret eder.",
                "Basit sözlü yönergeleri anlamaya başlar."
            ],
            socialEmotional: [
                "Başkalarının yaptığı hareketleri taklit eder.",
                "Sevdiği nesneleri gösterir.",
                "Tanıdık kişilere belirgin yakınlık gösterir."
            ],
            feedingTips: [
                "Çocuk aile yemeklerini yiyebilir; gerektiğinde ince doğranır veya ezilir.",
                "3–4 ana öğün ve 1–2 ara öğün; öğün başına yaklaşık 180 ml.",
                "Ek gıdadan beklenen enerji günde yaklaşık 550 kcal.",
                "İnek sütü artık ana içecek olarak verilebilir; tam yağlı tercih edilir.",
                "Bal artık verilebilir.",
                "İlave şekerli yiyecek ve içeceklerden 2 yaşına kadar kaçınılır.",
                "Anne sütü 2 yaşına kadar sürdürülebilir.",
                "Bütün üzüm, fındık ve sert şeker boğulma riski taşır — 3 yaşına kadar güvenli biçimde hazırlanır."
            ],
            sleepTips: [
                "Toplam 11–14 saat; genellikle tek öğleden sonra uykusu.",
                "Uyku düzeni yürümenin başlamasıyla geçici olarak bozulabilir."
            ],
            warningSigns: [
                "Birkaç adım bile atamama",
                "İstek veya yardım için işaret etmeme",
                "'Mama/dada' dışında hiç kelime denememe",
                "Nesneleri amacına uygun kullanmayı denememe",
                "Başkalarının hareketlerini taklit etmeme"
            ]
        ),

        GuideStage(
            id: "stage_15_18m",
            minWeeks: 65, maxWeeks: 78,
            title: "15–18 ay",
            summary: "Bağımsızlık artar; kelime dağarcığı genişler, seçici yeme başlayabilir.",
            grossMotor: [
                "Desteksiz yürür, koşmayı denemeye başlar.",
                "Alçak bir kanepeye çıkıp inebilir.",
                "Topa tekme atmayı deneyebilir."
            ],
            fineMotor: [
                "Karalama yapar.",
                "Bardaktan içer, kaşık kullanmayı dener.",
                "Giysilerinin bir bölümünü çıkarmaya yardım eder."
            ],
            language: [
                "'Mama' ve 'dada' dışında en az üç kelime söylemeye çalışır.",
                "İşaret ederek ilgi çekici bir şeyi gösterir.",
                "Jest olmadan tek aşamalı yönergeleri takip edebilir."
            ],
            socialEmotional: [
                "Ev işlerini taklit eder — süpürür gibi yapar.",
                "Bebeğini besliyormuş gibi basit sembolik oyun oynar.",
                "Yetişkinin yüzüne bakarak tepkisini kontrol eder."
            ],
            feedingTips: [
                "Seçici yeme bu dönemde normaldir; aynı besini birkaç kez sunmak gerekebilir.",
                "Çocuk ne kadar yiyeceğine kendi karar verir; ne sunulacağına ebeveyn karar verir.",
                "Öğünler aileyle birlikte, ekransız ve oturarak yenir.",
                "İlave şeker ve tuzdan kaçınmayı sürdürün.",
                "Meyve suyu yerine meyvenin kendisi tercih edilir; verilecekse günde en fazla 120 ml."
            ],
            sleepTips: [
                "Toplam 11–14 saat; genellikle tek öğleden sonra uykusu.",
                "Tutarlı bir yatma rutini geçişleri kolaylaştırır."
            ],
            warningSigns: [
                "Desteksiz yürüyememe",
                "Üç kelimeden az söz dağarcığı veya yeni kelime kazanamama",
                "Hiç işaret etmeme",
                "Kaşık kullanmayı denememe, bardaktan içememe",
                "Kazanılmış becerilerin kaybı"
            ]
        ),

        GuideStage(
            id: "stage_18_24m",
            minWeeks: 78, maxWeeks: Int.max,
            title: "18–24 ay",
            summary: "İki kelimelik ifadeler başlar; çocuk aile sofrasının bir parçasıdır.",
            grossMotor: [
                "Koşar, topa tekme atar.",
                "Birkaç basamağı yardımla veya yardımsız çıkabilir.",
                "Mobilyalara tırmanıp iner."
            ],
            fineMotor: [
                "Kaşıkla yemeye çalışır.",
                "Kitap sayfalarını tek tek çevirmeye çalışır.",
                "Kapak ve düğme gibi mekanizmaları kullanmayı dener."
            ],
            language: [
                "En az iki kelimeyi birlikte söyler ('daha su', 'anne gel').",
                "Vücut bölümlerini gösterebilir.",
                "Basit yönergeleri takip eder."
            ],
            socialEmotional: [
                "Yeni durumlarda ebeveyninden güvence arar.",
                "Başkalarının üzgün olduğunu fark eder.",
                "Basit hayali oyunlar oynar."
            ],
            feedingTips: [
                "3–4 ana öğün ve 1–2 ara öğün; çocuk aile yemeklerini yer.",
                "İlave şekerli yiyecek ve içeceklerden 2 yaşına kadar kaçınılır.",
                "Anne sütü 2 yaşına kadar, istenirse sonrasında da sürdürülebilir.",
                "Kendi kendine yeme denemeleri dağınık olur — bu öğrenmenin parçasıdır.",
                "Bütün fındık ve sert besinler boğulma riski nedeniyle 3 yaşına kadar ezilerek verilir."
            ],
            sleepTips: [
                "Toplam 11–14 saat; genellikle tek öğleden sonra uykusu.",
                "Bazı çocuklar bu dönemde gündüz uykusunu bırakmaya başlayabilir."
            ],
            warningSigns: [
                "Koşamama veya yürüyememe",
                "İki kelimeyi birlikte kullanmama",
                "Jest, işaret veya anlamlı iletişim kullanmama",
                "Başkalarının duygularını fark etmeme",
                "Kitap, oyuncak veya insanlarla etkileşime belirgin ilgisizlik",
                "Daha önce kazanılmış herhangi bir becerinin kaybı"
            ]
        )
    ]

    /// Bebeğin yaşına (haftalık) göre uygun gelişim aşamasını döner.
    static func stage(forAgeWeeks weeks: Int) -> GuideStage {
        stages.first { weeks >= $0.minWeeks && weeks < $0.maxWeeks } ?? stages.last!
    }
}
