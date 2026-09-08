import Foundation
import SwiftUI

/// Yenidoğan ve süt çocuğu için temel ilk yardım rehberi.
///
/// Kaynaklar: T.C. Sağlık Bakanlığı, Türk Pediatri Kurumu, American Heart
/// Association BLS for Healthcare Providers, AAP yenidoğan ilk yardım.
/// Bilgilendirme amaçlıdır; profesyonel eğitimin yerini tutmaz.
struct FirstAidStep: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let detail: String?
}

struct FirstAidScenario: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let summary: String
    let callEmergency: Bool          // ilk önce 112 araması gerekli mi?
    let callEmergencyWhen: [String]  // 112 aranması gereken ek durumlar
    let steps: [FirstAidStep]
    let warnings: [String]
}

enum FirstAidCatalog {
    static let scenarios: [FirstAidScenario] = [
        choking, chokingToddler, cpr, fever, fall, burn, drowning, noseBlock, allergy
    ]

    // MARK: - Boğulma (yabancı cisim)

    static let choking = FirstAidScenario(
        id: "choking",
        title: "Bebek Boğulması",
        icon: "lungs.fill",
        color: .red,
        summary: "Bebek bir cisim ile boğuluyor (nefes alamıyor, ağlamıyor, mavi/mor renk). Öğürme ile karıştırmayın.",
        callEmergency: true,
        callEmergencyWhen: [
            "Bebek bilincini kaybederse hemen 112'yi arayın.",
            "İlk müdahale işe yaramazsa veya bebek nefes almazsa 112."
        ],
        steps: [
            .init(id: 1, title: "Önce öğürme mü, boğulma mı ayırt edin",
                  detail: "Öğürmede bebek ses çıkarır, öksürür ve yüzü kızarır — bu koruyucu bir reflekstir, ek gıda döneminde sık görülür. Bekleyin, sırta vurmayın. Boğulmada ses yoktur: öksüremez, nefes alamaz, rengi morarır. Aşağıdaki adımlar yalnız boğulma içindir."),
            .init(id: 2, title: "112'yi arayın", detail: "Mümkünse hoparlöre alın; iki elinizi serbest tutun."),
            .init(id: 3, title: "Bebeği yüzükoyun çevirin",
                  detail: "Kolunuza yatırın, başı vücudundan aşağıda olacak şekilde. Çene açık tutulsun."),
            .init(id: 4, title: "Sırta 5 kez vurun",
                  detail: "Avuç içiyle iki kürek kemiği arasına orta şiddetle vurun."),
            .init(id: 5, title: "Cisim çıkmazsa ters çevirin",
                  detail: "Bebeği sırtüstü kolunuza yatırın, başı yine aşağıda."),
            .init(id: 6, title: "Göğüs ortasına 5 bası uygulayın",
                  detail: "İki parmağınızla göğüs kemiğinin alt yarısına bastırın (~4 cm derin, 5 hızlı bası)."),
            .init(id: 7, title: "Adımları tekrarlayın",
                  detail: "Cisim çıkana veya 112 ekibi gelene kadar 5 sırta vuruş + 5 göğüs basısını döngü halinde yapın."),
            .init(id: 8, title: "Bilinç kaybederse CPR'a geçin",
                  detail: "Aşağıdaki 'Bebek CPR' adımlarını uygulayın.")
        ],
        warnings: [
            "ASLA elinizle bebeğin ağzına körlemesine bir şey sokmayın.",
            "Ters Heimlich uygulamayın — bebeklerde kullanılmaz.",
            "Bebeği baş aşağı SALLAMAYIN.",
            "Öğüren bebeğe sırt vuruşu veya bası UYGULAMAYIN — öksürük en etkili temizleyicidir."
        ]
    )

    // MARK: - Boğulma (1 yaş üstü)

    static let chokingToddler = FirstAidScenario(
        id: "choking_toddler",
        title: "Çocuk Boğulması (1 yaş üstü)",
        icon: "lungs.fill",
        color: .red,
        summary: "1 yaşından büyük çocuk bir cisim ile boğuluyor. Öğürme ile karıştırmayın.",
        callEmergency: true,
        callEmergencyWhen: [
            "Çocuk konuşamıyor, öksüremiyor veya nefes alamıyorsa hemen 112.",
            "Bilinç kaybı gelişirse hemen 112.",
            "Cisim çıksa bile solunum düzelmiyorsa 112."
        ],
        steps: [
            .init(id: 1, title: "Önce öğürme mü, boğulma mı ayırt edin",
                  detail: "Öğüren çocuk ses çıkarır ve öksürür — müdahale etmeyin, öksürmesine izin verin. Boğulmada ses yoktur, ellerini boğazına götürebilir, rengi morarır."),
            .init(id: 2, title: "112'yi arayın",
                  detail: "Yanınızda biri varsa o arasın; siz müdahaleye başlayın."),
            .init(id: 3, title: "Sırta 5 kez vurun",
                  detail: "Çocuğu öne eğdirin, avuç içiyle iki kürek kemiği arasına vurun."),
            .init(id: 4, title: "Karın baskısı uygulayın (5 kez)",
                  detail: "Arkasından sarılın, yumruğunuzu göbek ile göğüs kemiği arasına koyun, diğer elinizle kavrayıp içeri ve yukarı doğru bastırın. Bu manevra 1 yaş altında UYGULANMAZ, 1 yaş üstünde uygulanır."),
            .init(id: 5, title: "Adımları tekrarlayın",
                  detail: "Cisim çıkana veya 112 ekibi gelene kadar 5 sırta vuruş + 5 karın baskısını döngü halinde sürdürün."),
            .init(id: 6, title: "Bilinç kaybederse CPR'a geçin",
                  detail: "Çocuğu yere yatırın ve temel yaşam desteğine başlayın.")
        ],
        warnings: [
            "Öğüren çocuğa müdahale ETMEYİN — öksürük en etkili temizleyicidir.",
            "Ağza körlemesine parmak sokmayın; cismi daha derine itebilirsiniz.",
            "Karın baskısı sonrası cisim çıksa bile çocuk hekime gösterilmelidir.",
            "Bütün üzüm, kuruyemiş ve sert şeker 3 yaşına kadar bu riskin en sık nedenleridir."
        ]
    )

    // MARK: - CPR (bebek)

    static let cpr = FirstAidScenario(
        id: "cpr",
        title: "Bebek CPR (Kalp Masajı)",
        icon: "heart.fill",
        color: .red,
        summary: "Bebek nefes almıyor veya kalp atışı yok.",
        callEmergency: true,
        callEmergencyWhen: [
            "Hemen 112'yi arayın — başka biri varsa siz CPR'a başlayın, o arasın."
        ],
        steps: [
            .init(id: 1, title: "112'yi arayın", detail: "Yardım çağırın. Tek başınızaysanız 1 dakika CPR sonrası arayın."),
            .init(id: 2, title: "Düz, sert bir yüzeye yatırın",
                  detail: "Bebeği sırtüstü yatırın, başını hafifçe geriye eğin."),
            .init(id: 3, title: "Ağız ağıza solunum başlatın",
                  detail: "Ağzınızla bebeğin ağız ve burnunu kapatın, 1 saniye süren 2 nefes verin. Göğüs yükselsin."),
            .init(id: 4, title: "30 göğüs basısı uygulayın",
                  detail: "Göğüs kemiğinin alt yarısına 2 parmakla bastırın. Derinlik: ~4 cm. Hız: dakikada 100-120 bası."),
            .init(id: 5, title: "2 nefes + 30 bası döngüsü",
                  detail: "Bu döngüyü ambulans gelene veya bebek tepki verene kadar sürdürün."),
            .init(id: 6, title: "Bebek yanıt verirse",
                  detail: "Yan yatış pozisyonuna alın, solunumu izleyin.")
        ],
        warnings: [
            "Çok güçlü üflemeyin — bebek akciğeri küçüktür.",
            "Bebeği yataktan yere düşürmeyin; sert ama güvenli yüzeye yerleştirin.",
            "112 ekibi geldiğinde durumu özetleyin: kaç dakikadır CPR yapıldı, ne oldu."
        ]
    )

    // MARK: - Ani yüksek ateş

    static let fever = FirstAidScenario(
        id: "high_fever",
        title: "Ani Yüksek Ateş",
        icon: "thermometer.high",
        color: .orange,
        summary: "Bebeğin koltuk altı sıcaklığı 38°C üzerine çıktı (özellikle 3 aydan küçükse).",
        callEmergency: false,
        callEmergencyWhen: [
            "3 aydan küçük bebekte 38°C üzeri her ateş için hemen acile gidin.",
            "Ateş havalesi (titreme, kasılma) olursa 112.",
            "Bebek halsizleşir, uyandırılamaz, beslenmiyor veya nefes hızlıysa acile."
        ],
        steps: [
            .init(id: 1, title: "Ateşi doğru ölçün",
                  detail: "Dijital termometre ile koltuk altından. 5 dakika bekleyin."),
            .init(id: 2, title: "İnce kıyafete geçirin",
                  detail: "Battaniye ve kalın giysiyi çıkarın. Oda 22°C civarında olsun."),
            .init(id: 3, title: "Bol sıvı verin",
                  detail: "Anne sütü/mama ile beslemeye devam edin."),
            .init(id: 4, title: "Ilık su ile silebilirsiniz",
                  detail: "Buz ya da kolonyalı su KULLANMAYIN. Sadece ılık (vücut sıcaklığında) suyla."),
            .init(id: 5, title: "Doktor önermeden ilaç vermeyin",
                  detail: "3 aydan büyük bebeklerde, sadece pediatristin önerdiği dozda parasetamol (Calpol).")
        ],
        warnings: [
            "Buzlu su, soğuk duş veya alkol kesinlikle KULLANMAYIN.",
            "Aspirin (Aspirin, Coraspin) bebeklere VERİLMEZ — Reye sendromu riski.",
            "Önerilenden fazla ateş düşürücü vermeyin."
        ]
    )

    // MARK: - Düşme / kafa travması

    static let fall = FirstAidScenario(
        id: "fall",
        title: "Düşme / Kafa Çarpması",
        icon: "exclamationmark.octagon.fill",
        color: .orange,
        summary: "Bebek yataktan, masadan veya kolundan düştü. Kafasını çarptı.",
        callEmergency: false,
        callEmergencyWhen: [
            "Bilinç kaybı, uyandırılamama → 112.",
            "Kusma, kasılma, nöbet → 112.",
            "Burun veya kulaktan kan / berrak sıvı → 112.",
            "Gözbebekleri farklı boyutta → 112.",
            "Sürekli ağlama 1 saatten uzun, beslenmiyor → acile gidin."
        ],
        steps: [
            .init(id: 1, title: "Hemen bebeği kaldırmayın",
                  detail: "Eğer hareketsiz ya da garip pozisyonda ise dokunmadan 112'yi arayın."),
            .init(id: 2, title: "Bilinç ve solunumu kontrol edin",
                  detail: "Adıyla seslenin, hafifçe omzuna dokunun. Tepki var mı?"),
            .init(id: 3, title: "Çarpma yerine soğuk kompres",
                  detail: "Buz dolu beze sarın (asla doğrudan tene değil), 10-15 dk uygulayın."),
            .init(id: 4, title: "24 saat yakından izleyin",
                  detail: "Davranış değişikliği, uyku hâli, beslenme azlığı, kusma için dikkatli olun."),
            .init(id: 5, title: "Kuşku varsa pediatristi arayın",
                  detail: "Şüpheniz varsa beklemeyin, sağlık kuruluşuna başvurun.")
        ],
        warnings: [
            "Bilinçli ama dengesizse aspirin/ağrı kesici vermeyin — değerlendirme bozulur.",
            "Çarpma sonrası ilk 6 saat en kritik dönemdir.",
            "Yumurta sürmek, kolonya gibi geleneksel yöntemler işe yaramaz."
        ]
    )

    // MARK: - Yanık

    static let burn = FirstAidScenario(
        id: "burn",
        title: "Yanık (Sıcak Su / Buhar)",
        icon: "flame.fill",
        color: .red,
        summary: "Bebeğin cildi yandı (sıcak süt, çay, ütü, buhar vs.).",
        callEmergency: false,
        callEmergencyWhen: [
            "2x2 cm'den geniş yanık → acile gidin.",
            "Yüz, eller, genital bölge, eklem yerleri → acile.",
            "Kabarcık oluşmuşsa veya cilt soyulduysa → acile.",
            "Solunum yolu yanığı şüphesi (buhar/kimyasal) → 112."
        ],
        steps: [
            .init(id: 1, title: "Sıcaktan uzaklaştırın",
                  detail: "Bebeği derhal sıcaklıktan ayırın. Ütü, kabloyu vs. güvene alın."),
            .init(id: 2, title: "Hemen akan ılık su tutun",
                  detail: "Yanık bölgesine 15-20 dakika ılık (soğuk değil) su tutun. Buz KULLANMAYIN."),
            .init(id: 3, title: "Giysiyi yapışıksa çıkartmaya çalışmayın",
                  detail: "Yapışan kumaşı zorla çıkarmayın — bekleyin."),
            .init(id: 4, title: "Steril bezle örtün",
                  detail: "Temiz, kuru, tüy bırakmaz bir bezle hafifçe örtün."),
            .init(id: 5, title: "Acile götürün",
                  detail: "Küçük bir yanık bile bebekte ciddi etki yapabilir.")
        ],
        warnings: [
            "Yanığa diş macunu, yumurta akı, tereyağı, salça SÜRMEYİN — enfeksiyon riski.",
            "Kabarcığı PATLATMAYIN.",
            "Buz veya buzlu su KULLANMAYIN — dokuya zarar verir."
        ]
    )

    // MARK: - Suda boğulma

    static let drowning = FirstAidScenario(
        id: "drowning",
        title: "Suda Boğulma",
        icon: "drop.fill",
        color: .blue,
        summary: "Bebek küvet, havuz veya kovada suya girdi, nefes almıyor.",
        callEmergency: true,
        callEmergencyWhen: [
            "Hemen 112'yi arayın — su yutmadığını anlasanız bile."
        ],
        steps: [
            .init(id: 1, title: "Bebeği sudan çıkarın",
                  detail: "Mümkünse boyun sabit tutarak. Düz bir yüzeye yatırın."),
            .init(id: 2, title: "Solunumu kontrol edin",
                  detail: "5 saniye gözlemleyin: göğüs hareketi, ağızdan nefes hissi."),
            .init(id: 3, title: "Solumuyorsa CPR'a başlayın",
                  detail: "Yukarıdaki 'Bebek CPR' adımlarını uygulayın."),
            .init(id: 4, title: "Soluyorsa yan yatırın",
                  detail: "Yan pozisyonda yatırın, sırtını okşayarak suyu çıkarmasına izin verin."),
            .init(id: 5, title: "Sıcak tutun",
                  detail: "Islak giysileri çıkarın, kuru havluyla sarın."),
            .init(id: 6, title: "Acile götürün",
                  detail: "Bebek normal görünse bile suya batma sonrası mutlaka muayene olunmalı (sekonder boğulma riski).")
        ],
        warnings: [
            "Bebeği baş aşağı tutup salla METHODU UYGULAMAYIN — eski/yanlış bir yöntem.",
            "Suyu \"çıkartmaya\" çalışıp midesine bastırmayın — kusturup boğmanıza yol açar.",
            "Sekonder boğulma 24 saat içinde gelişebilir, mutlaka muayene gerekir."
        ]
    )

    // MARK: - Burun tıkanıklığı

    static let noseBlock = FirstAidScenario(
        id: "nose_block",
        title: "Burun Tıkanıklığı",
        icon: "wind",
        color: .cyan,
        summary: "Bebek burnu tıkalı için zorlanıyor, beslenirken nefes alamıyor.",
        callEmergency: false,
        callEmergencyWhen: [
            "Solunum sayısı dakikada 60'tan fazla → acile.",
            "Cilt rengi mavileşirse → 112.",
            "Hırıltı, inleme, burun delikleri açılarak nefes → acile."
        ],
        steps: [
            .init(id: 1, title: "Steril serum fizyolojik damla",
                  detail: "Her burun deliğine 2-3 damla. Eczaneden hazır ampuller alın."),
            .init(id: 2, title: "Birkaç dakika bekleyin",
                  detail: "Salgıların yumuşaması için."),
            .init(id: 3, title: "Aspiratörle çekin",
                  detail: "Bebek burun aspiratörü ile yavaşça çekin. Çok kuvvetli çekmeyin."),
            .init(id: 4, title: "Buharlı ortam oluşturun",
                  detail: "Banyoda sıcak duş açarak buhar yaratabilirsiniz (bebeği duşa sokmayın)."),
            .init(id: 5, title: "Uykuda baş hafif yüksek",
                  detail: "Şilteyi 30° yatık tutun — yastık KULLANMAYIN, sadece şilte altına yastık koyun.")
        ],
        warnings: [
            "Yetişkin burun spreyleri KULLANMAYIN.",
            "Pamuklu çubuğu burun içine sokmayın.",
            "Soğan/sarımsak gibi geleneksel yöntemler nefes yollarını tahriş edebilir."
        ]
    )

    // MARK: - Alerji / anafilaksi

    static let allergy = FirstAidScenario(
        id: "allergy",
        title: "Alerjik Reaksiyon",
        icon: "allergens.fill",
        color: .pink,
        summary: "Bebekte ani döküntü, yüz şişmesi, kusma veya nefes darlığı.",
        callEmergency: true,
        callEmergencyWhen: [
            "Dudak/dil/yüz şişmesi → 112.",
            "Nefes darlığı, hırıltı, öksürük → 112.",
            "Bilinç değişikliği, halsizlik → 112.",
            "Tüm vücut döküntüsü + ateş → acile."
        ],
        steps: [
            .init(id: 1, title: "112'yi arayın",
                  detail: "Anafilaksi belirtilerinde bekleme — derhal arayın."),
            .init(id: 2, title: "Reçeteli adrenaliniz varsa hemen uygulayın",
                  detail: "Çocuğunuz için daha önce adrenalin oto-enjektörü reçete edildiyse, anafilaksi belirtilerinde beklemeden uyluğun ön-yan yüzüne uygulayın. Belirtiler 5 dakikada düzelmezse ikinci doz gerekebilir — 112 ekibiyle konuşun."),
            .init(id: 3, title: "Bebeği sırtüstü yatırın",
                  detail: "Nefes alıyorsa yan yatış pozisyonu daha güvenli. Ayağa kaldırıp dolaştırmayın."),
            .init(id: 4, title: "Şüpheli besini durdurun",
                  detail: "Son verdiğiniz yeni gıdayı (yumurta, süt, fıstık) not edin."),
            .init(id: 5, title: "Soluk almaya yardım",
                  detail: "Kollarını yana açın, dik tutun. Solunum durduysa CPR'a başlayın."),
            .init(id: 6, title: "Bilgi toplayın",
                  detail: "Doktora söylemek için: ne yedi, ne zaman, hangi belirti ne sıra ile çıktı.")
        ],
        warnings: [
            "Antihistaminik yalnızca deri belirtilerini azaltabilir; adrenalinin YERİNE GEÇMEZ.",
            "Doktor önermeden ev tipi antihistaminik (Avil vs.) VERMEYİN.",
            "Anafilaksi sıklıkla 30 dk içinde başlar — geçti sanmayın, mutlaka muayene.",
            "Bal vermeyin (1 yaş altı botulizm riski)."
        ]
    )
}
