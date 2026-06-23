import Foundation
import SwiftUI

/// Aciliyet seviyesi — renk ve aksiyon önerisi içerir.
enum Urgency: String, Codable, CaseIterable, Sendable {
    case normal     // 🟢 İzle, çoğunlukla normal
    case warning    // 🟡 Bugün/yarın doktora başvur
    case emergency  // 🔴 ACİL — hemen hastane ya da 112

    var title: String {
        switch self {
        case .normal:    return "İzleyin"
        case .warning:   return "Doktora Başvurun"
        case .emergency: return "ACİL — Hemen Hastaneye"
        }
    }

    var color: Color {
        switch self {
        case .normal:    return .green
        case .warning:   return .orange
        case .emergency: return .red
        }
    }

    var icon: String {
        switch self {
        case .normal:    return "checkmark.circle.fill"
        case .warning:   return "exclamationmark.triangle.fill"
        case .emergency: return "exclamationmark.octagon.fill"
        }
    }
}

/// Bir belirti kategorisi altında özel bir durum + uygun yanıt.
struct SymptomScenario: Identifiable, Hashable, Sendable {
    let id: String
    let label: String           // "Vücut sıcaklığı 38°C üzeri (0–3 aylık)"
    let urgency: Urgency
    let advice: String          // kısa özet
    let nextSteps: [String]     // madde madde önlem/aksiyon
}

/// Belirti kategorisi (ateş, kusma, vs.)
struct SymptomCategory: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let icon: String            // SF Symbol
    let color: Color
    let prompt: String          // detay ekranında üst metin
    let scenarios: [SymptomScenario]
}

// MARK: - İçerik
// Kaynak: T.C. Sağlık Bakanlığı bebek bakımı rehberi, AAP (American Academy
// of Pediatrics) genel öneriler, NHS pediatrik triyaj kılavuzu. Bilgilendirme
// amaçlıdır; hekim önerisinin yerini tutmaz.

enum SymptomCatalog {
    static let categories: [SymptomCategory] = [
        ateş,
        kusma,
        kaka,
        beslenme,
        idrar,
        solunum,
        ağlama,
        uyku,
        sarılık,
        ciltVeRenk,
        göbekBakımı,
        bıngıldak,
        kasılma,
        gazVeKabızlık,
        gözAkıntısı,
        hıçkırık,
        pamukçuk,
        hapşırmaVeÖksürük
    ]

    // MARK: - Göbek Bakımı

    static let göbekBakımı = SymptomCategory(
        id: "umbilical",
        title: "Göbek Bakımı",
        icon: "circle.dotted.circle",
        color: .pink,
        prompt: "Göbek bağı 7–21 gün içinde kendi düşer. O zamana kadar temiz ve kuru tutun. Aşağıdaki durumlara dikkat edin.",
        scenarios: [
            .init(id: "umb_drying",
                  label: "Kuruyor, koyulaşıyor, çevresinde kızarıklık yok",
                  urgency: .normal,
                  advice: "Normal — göbek bağı düşmeye hazırlanıyor.",
                  nextSteps: [
                    "Bezin üst kısmını göbeğin altına gelecek şekilde kıvırın (havalansın).",
                    "Sıkı/dar kıyafet giydirmeyin.",
                    "Tuzlu su, alkol, betadin, kolonya SÜRMEYİN — hekim önermedi ise.",
                    "Banyo: kalkık göbekle hızlı yıkayın, kurutun."
                  ]),
            .init(id: "umb_minor_blood",
                  label: "Düşerken 3–4 damla kanama veya sarı leke",
                  urgency: .normal,
                  advice: "Düşme sırasında küçük kanama veya sarı/kahverengi leke normaldir.",
                  nextSteps: [
                    "Temiz pamukla hafifçe silin.",
                    "Yapışkan bant veya sargı bağlamayın.",
                    "1–2 gün içinde geçer."
                  ]),
            .init(id: "umb_smell",
                  label: "Kötü koku, sarı-yeşilimsi akıntı",
                  urgency: .warning,
                  advice: "Hafif enfeksiyon olabilir — bugün doktora gidin.",
                  nextSteps: [
                    "Pediatristinize başvurun.",
                    "Koku tarif edin, fotoğraf çekin.",
                    "Bezi göbeğin altına kıvırın, hava alsın."
                  ]),
            .init(id: "umb_omphalitis",
                  label: "Göbek çevresi kızarık, şişlik, ateş, halsizlik",
                  urgency: .emergency,
                  advice: "Omfalit olabilir — yenidoğanlar için hayati enfeksiyon. Acil!",
                  nextSteps: [
                    "Hemen acile gidin.",
                    "Kızarıklığın sınırını kalemle çizip not edin — yayılım hızı kritik.",
                    "Ateş ölçün, beslenmeye devam edin."
                  ]),
            .init(id: "umb_hernia",
                  label: "Göbek küçük çıkıntı yapıyor (fıtık şüphesi)",
                  urgency: .normal,
                  advice: "Göbek fıtığı yenidoğanların %20'sinde görülür; çoğu 1–2 yaşına kadar kendi kapanır.",
                  nextSteps: [
                    "Sıradaki kontrolde pediatriste gösterin.",
                    "Fıtığın üstüne para, bant, tampon BASTIRMAYIN — yarar değil zarar verir."
                  ])
        ]
    )

    // MARK: - Bıngıldak (fontanel)

    static let bıngıldak = SymptomCategory(
        id: "fontanel",
        title: "Bıngıldak",
        icon: "circle.fill",
        color: .purple,
        prompt: "Bıngıldak (fontanel) — kafatasının kapatılmamış yumuşak kısmı. 18 aya kadar açık kalır, yumuşakça dokunmak güvenlidir.",
        scenarios: [
            .init(id: "fontanel_normal",
                  label: "Düz, hafifçe çökük veya nabızla titreşiyor",
                  urgency: .normal,
                  advice: "Normal — kalp atışıyla titreşim sık görülen ve normal bir durumdur.",
                  nextSteps: [
                    "Bebeği şampuanlarken endişe etmeyin, dokunmak zarar vermez.",
                    "Düzenli pediatrist kontrolünde takip edilir."
                  ]),
            .init(id: "fontanel_sunken",
                  label: "Belirgin çökmüş, ağız kuru, az idrar",
                  urgency: .warning,
                  advice: "Dehidratasyon işareti — sıvı kaybı var.",
                  nextSteps: [
                    "Bugün doktora başvurun.",
                    "Beslemeye devam edin (anne sütü/mama).",
                    "Halsizleşir veya hiç idrar etmezse acile gidin."
                  ]),
            .init(id: "fontanel_bulging",
                  label: "Şişmiş, gergin, ağladığında değil sakinken de kabarık",
                  urgency: .emergency,
                  advice: "Kafa içi basıncı artmış olabilir — menenjit, kanama veya hidrosefali şüphesi.",
                  nextSteps: [
                    "Hemen acile gidin veya 112'yi arayın.",
                    "Ateş, kusma, halsizlik var mı not edin."
                  ]),
            .init(id: "fontanel_closed_early",
                  label: "6 aydan önce tamamen kapanmış gibi geliyor",
                  urgency: .warning,
                  advice: "Erken kapanma kafatası gelişimini etkileyebilir — değerlendirme şart.",
                  nextSteps: [
                    "Pediatristinize başvurun.",
                    "Düzenli kafa çevresi ölçümü yaptırın."
                  ])
        ]
    )

    // MARK: - Kasılma / Refleks

    static let kasılma = SymptomCategory(
        id: "seizure",
        title: "Kasılma / Titreme",
        icon: "waveform.path.ecg",
        color: .red,
        prompt: "Bebekteki istemsiz hareketin türünü seçin. Refleksler (Moro, titreme) normal; ritmik kasılma değildir.",
        scenarios: [
            .init(id: "sz_moro",
                  label: "Ani sese karşı kollarını açıp kapatma (Moro refleksi)",
                  urgency: .normal,
                  advice: "Moro refleksi — yenidoğanın yerleşik refleksi. 4–6. ayda kaybolur.",
                  nextSteps: [
                    "Yumuşak kundak (swaddling) bebeği rahatlatır.",
                    "Sesli ortamdan uzak tutun.",
                    "5–6 aydan sonra hâlâ belirginse pediatriste danışın."
                  ]),
            .init(id: "sz_tremor",
                  label: "Çene/el titreme — beslenme veya ağlama sırasında, durdurulabilir",
                  urgency: .normal,
                  advice: "Tremor (titreme) yenidoğanlarda normaldir; bebeğin uzvunu tuttuğunuzda durur.",
                  nextSteps: [
                    "Bebeği sarın, dokunarak sakinleştirin.",
                    "Beslenme sonrasında titreme uzarsa kan şekeri kontrolü için doktora başvurun."
                  ]),
            .init(id: "sz_rhythmic",
                  label: "Ritmik kasılma, tutulamıyor, gözler sabit veya bir tarafa kayık",
                  urgency: .emergency,
                  advice: "Nöbet — acil değerlendirme şart.",
                  nextSteps: [
                    "Hemen 112'yi arayın.",
                    "Bebeği yan yatırın, etrafındaki sert nesneleri kaldırın.",
                    "Ağzına KESİNLİKLE bir şey sokmayın.",
                    "Süresini saatle ölçün, mümkünse video kaydedin (doktora gösterin)."
                  ]),
            .init(id: "sz_apnea",
                  label: "Hareketsiz kalma + nefes durması + cilt rengi değişimi",
                  urgency: .emergency,
                  advice: "Apneik nöbet — yaşamsal acil.",
                  nextSteps: [
                    "Hemen 112'yi arayın.",
                    "Bebeği uyarın (ovun, isim seslenin).",
                    "Solumuyorsa CPR'a başlayın."
                  ])
        ]
    )

    // MARK: - Gaz ve Kabızlık

    static let gazVeKabızlık = SymptomCategory(
        id: "gas_constipation",
        title: "Gaz / Kabızlık",
        icon: "wind.circle.fill",
        color: .orange,
        prompt: "Sadece anne sütü alan bebeklerde günde 1 ile haftada 1 arası kakalama normaldir. Kıvam ve bebeğin huzuru önemlidir.",
        scenarios: [
            .init(id: "gas_normal",
                  label: "Sık gaz çıkarıyor, huzursuz ama yumuşak kaka yapıyor",
                  urgency: .normal,
                  advice: "Yenidoğan sindirim sistemi olgunlaşırken yoğun gaz üretir — normaldir.",
                  nextSteps: [
                    "Her öğünden sonra dik tutup gaz çıkarmaya yardım edin.",
                    "Bisiklet hareketi: bebeğin bacaklarını döndürün.",
                    "Karın masajı: saat yönünde, sıcak elle.",
                    "Doğru kavrama emzirme/biberonda hava yutmayı azaltır."
                  ]),
            .init(id: "gas_bm_only_rare",
                  label: "Sadece anne sütü alıyor, 5–7 günde bir kaka yapıyor, yumuşak ve huzurlu",
                  urgency: .normal,
                  advice: "Tamamen anne sütü alan bebeklerde uzun aralıklar normal — anne sütü neredeyse tamamen sindirilir.",
                  nextSteps: [
                    "Bebek aktif ve kilo alıyorsa endişe etmeyin.",
                    "Karın şişkin değil, hassas değilse beklemek güvenli."
                  ]),
            .init(id: "gas_hard_stool",
                  label: "Kuru sert kaka, çıkarken ağrılı, ıkınma + ağlama",
                  urgency: .warning,
                  advice: "Yenidoğanda gerçek kabızlık nadirdir; doktorla görüşün.",
                  nextSteps: [
                    "Pediatristinize başvurun.",
                    "Mama alıyorsa sulandırma oranını kontrol ettirin.",
                    "Asla bal, gliserinli supozituar VE hiçbir ev müdahalesi YAPMAYIN — doktor önerisi şart."
                  ]),
            .init(id: "gas_no_stool_long",
                  label: "4+ gün hiç kaka yok + halsizlik + karın şişliği + kusma",
                  urgency: .emergency,
                  advice: "Bağırsak tıkanıklığı şüphesi — acil.",
                  nextSteps: [
                    "Acile gidin.",
                    "Bir şey yedirmeyin.",
                    "Karın çevresini ölçüp not edin."
                  ]),
            .init(id: "gas_baby_colic",
                  label: "Her gün aynı saatte 2+ saat dindirilemeyen ağlama, gaz çıkarma",
                  urgency: .normal,
                  advice: "Bebek koliği olabilir — 3 hafta–4 ay arası yaygın, çoğu 4. ayda geçer.",
                  nextSteps: [
                    "Sallama, kundak, beyaz gürültü dene.",
                    "Annenin diyetinde süt ürünü/kafein varsa 1 hafta kesip deneme yap.",
                    "Geçmezse pediatristle paylaşın — başka neden ekarte edilir."
                  ])
        ]
    )

    // MARK: - Göz Akıntısı

    static let gözAkıntısı = SymptomCategory(
        id: "eye_discharge",
        title: "Göz Akıntısı",
        icon: "eye.fill",
        color: .blue,
        prompt: "Bebeğin gözünde fark ettiğiniz duruma göre seçin.",
        scenarios: [
            .init(id: "eye_tear_duct",
                  label: "Tek gözde sarımsı leke, göz beyazı normal, kapaklar şişmiyor",
                  urgency: .normal,
                  advice: "Göz yaşı kanalı tıkanıklığı — yenidoğanların %20'sinde görülür, çoğu 1 yaşa kadar kendi geçer.",
                  nextSteps: [
                    "Steril gazlı bezi ılık suyla ıslatın, gözü iç köşeden dışa silin.",
                    "Hafif masaj: göz iç köşesini parmakla yumuşakça aşağı yönlü ovun (3-5 kez, günde 3 kez).",
                    "Düzenli pediatrist kontrolünde takip edilir."
                  ]),
            .init(id: "eye_conjunctivitis",
                  label: "Her iki gözde sulanma + sarı/yeşil akıntı + göz kapakları kızarık/şiş",
                  urgency: .warning,
                  advice: "Konjunktivit (göz iltihabı) — bugün doktora başvurun.",
                  nextSteps: [
                    "Pediatristinize başvurun — damla/krem reçetesi gerekebilir.",
                    "Her gözü ayrı temiz pamukla silin (bulaşı önler).",
                    "Bebek yastığını, havlusunu yıkayın."
                  ]),
            .init(id: "eye_newborn_24h",
                  label: "Doğumdan sonraki ilk 24 saatte göz akıntısı",
                  urgency: .emergency,
                  advice: "Doğum sonrası ilk gün göz akıntısı gonokok/klamidya enfeksiyonu olabilir.",
                  nextSteps: [
                    "Hemen pediatristinize veya doğum hastanesine başvurun.",
                    "Antibiyotik tedavisi 48 saat içinde başlamalı."
                  ]),
            .init(id: "eye_eyelid_swollen",
                  label: "Göz kapağı şiş + ateş + bebek huzursuz",
                  urgency: .emergency,
                  advice: "Selülit (yumuşak doku enfeksiyonu) şüphesi — acil.",
                  nextSteps: [
                    "Acile gidin.",
                    "Sıcak/soğuk kompres uygulamayın — doktor değerlendirsin."
                  ])
        ]
    )

    // MARK: - Hıçkırık

    static let hıçkırık = SymptomCategory(
        id: "hiccup",
        title: "Hıçkırık",
        icon: "bubble.left.fill",
        color: .cyan,
        prompt: "Yenidoğanlarda hıçkırık çok yaygındır ve neredeyse her zaman zararsızdır.",
        scenarios: [
            .init(id: "hic_normal",
                  label: "Beslenme sırasında veya sonrasında 5–15 dk hıçkırık",
                  urgency: .normal,
                  advice: "Tamamen normal — diyafram kası henüz olgunlaşmamış.",
                  nextSteps: [
                    "Dikey tutarak gaz çıkartın.",
                    "Birkaç dakika içinde kendiliğinden geçer.",
                    "Bebek huzursuz değilse müdahaleye gerek yok."
                  ]),
            .init(id: "hic_long",
                  label: "Hıçkırık 1+ saat sürüyor",
                  urgency: .normal,
                  advice: "Uzun hıçkırık genelde zararsızdır ama bebek rahatsız oluyorsa müdahale denenebilir.",
                  nextSteps: [
                    "Bebeği dik tutun, sırtını okşayın.",
                    "Bir öğün daha emzirmeyi deneyin (yutkunma diyafragmayı durdurur).",
                    "Asla soğuk bir şey içirmeyin, korkutmaya çalışmayın."
                  ]),
            .init(id: "hic_with_vomit",
                  label: "Hıçkırıkla birlikte sürekli kusma veya öksürük",
                  urgency: .warning,
                  advice: "Reflü veya sindirim sorunu eşlik ediyor olabilir.",
                  nextSteps: [
                    "Pediatristinize başvurun.",
                    "Beslenme sonrası 20–30 dk dik tutun.",
                    "Doktor önermeden reflü ilacı vermeyin."
                  ])
        ]
    )

    // MARK: - Pamukçuk

    static let pamukçuk = SymptomCategory(
        id: "thrush",
        title: "Pamukçuk (Ağız)",
        icon: "mouth.fill",
        color: .pink,
        prompt: "Bebeğin dili veya yanak içinde beyaz plak fark ettiyseniz seçin.",
        scenarios: [
            .init(id: "thrush_milk_residue",
                  label: "Sadece dil üstünde beyaz tabaka, kolayca silinir",
                  urgency: .normal,
                  advice: "Süt kalıntısı — normal, pamukçuk değil.",
                  nextSteps: [
                    "Bezi ıslak, temiz parmağa sarıp dili nazikçe silin.",
                    "Beslenme sonrası birkaç damla su (sadece 6 aydan büyükse) verilebilir."
                  ]),
            .init(id: "thrush_plaques",
                  label: "Dil, yanak içi ve damaşta beyaz plaklar; silinmiyor veya silindiğinde kırmızı kalır",
                  urgency: .warning,
                  advice: "Oral kandida (pamukçuk) — antifungal tedavi gerekir.",
                  nextSteps: [
                    "Pediatristinize gidin (nystatin damla reçete edilir).",
                    "Emzikleri, biberon başlıklarını kaynar suda 10 dk dezenfekte edin.",
                    "Emziren anne meme ucunu kontrol ettirsin (geçişli enfeksiyon)."
                  ]),
            .init(id: "thrush_refusing_feed",
                  label: "Pamukçuk + beslenmeyi reddediyor, ağız ağrılı görünüyor",
                  urgency: .warning,
                  advice: "Bugün doktora başvurun — sıvı kaybı riski.",
                  nextSteps: [
                    "Pediatristinizi bugün arayın.",
                    "Sıvı alımını izleyin (ıslak bez sayısı)."
                  ])
        ]
    )

    // MARK: - Hapşırma ve Öksürük

    static let hapşırmaVeÖksürük = SymptomCategory(
        id: "sneeze_cough",
        title: "Hapşırma / Öksürük",
        icon: "wind",
        color: .teal,
        prompt: "Yenidoğanlar burun temizliği için sık hapşırır. Öksürük ise yenidoğanda nadirdir ve dikkat ister.",
        scenarios: [
            .init(id: "sn_normal",
                  label: "Günde birkaç kez hapşırma, salgı yok, ateş yok",
                  urgency: .normal,
                  advice: "Yenidoğanın burun temizleme yöntemi — tamamen normal.",
                  nextSteps: [
                    "Bebeği toza, kokuya, sigara dumanına maruz bırakmayın.",
                    "Oda nemini %40–60 arasında tutun."
                  ]),
            .init(id: "sn_frequent",
                  label: "Çok sık hapşırma + akıntı + tıkanıklık",
                  urgency: .normal,
                  advice: "Hafif soğuk algınlığı veya alerjik tepki olabilir.",
                  nextSteps: [
                    "Steril serum fizyolojikle burnu temizleyin.",
                    "Sıvı alımını artırın.",
                    "37.5°C üzeri ateş veya solunum güçlüğü olursa doktora."
                  ]),
            .init(id: "cough_newborn",
                  label: "Yenidoğan (<3 ay) sürekli öksürüyor",
                  urgency: .warning,
                  advice: "Yenidoğanda öksürük seyrektir; mutlaka doktor değerlendirsin.",
                  nextSteps: [
                    "Bugün pediatristinize başvurun.",
                    "Ateş, solunum sayısı (dakikada), beslenme durumunu not edin."
                  ]),
            .init(id: "cough_whoop",
                  label: "Öksürük + 'huu' sesli derin nefes alma + morarma",
                  urgency: .emergency,
                  advice: "Boğmaca (pertussis) şüphesi — yaşamsal tehlike.",
                  nextSteps: [
                    "112'yi arayın veya acile gidin.",
                    "Hane içi temaslıları (büyükler) bildirin — boğmaca hızlı bulaşır.",
                    "Aşı geçmişini doktora söyleyin."
                  ]),
            .init(id: "breath_wheeze",
                  label: "Öksürükle birlikte hırıltı, dakikada 60+ nefes",
                  urgency: .emergency,
                  advice: "Bronşiyolit veya pnömoni olabilir.",
                  nextSteps: [
                    "Acile gidin veya 112'yi arayın.",
                    "Bebeği dik tutun, sıvı vermeye devam edin.",
                    "Solunum sayısını ve cilt rengi değişimini doktora bildirin."
                  ])
        ]
    )

    // MARK: - Mevcut kategoriler

    static let ateş = SymptomCategory(
        id: "fever",
        title: "Ateş",
        icon: "thermometer",
        color: .red,
        prompt: "Bebeğinizin koltuk altı ölçümüne göre seçin. 0–3 ay grubu için 38°C'nin üzerindeki her değer acildir.",
        scenarios: [
            .init(id: "fever_under3m_38plus",
                  label: "0–3 aylık + 38°C ve üzeri",
                  urgency: .emergency,
                  advice: "3 aydan küçük bebeklerde 38°C üzeri her ateş ciddi enfeksiyon işareti olabilir.",
                  nextSteps: [
                    "Hemen acil servise gidin veya 112'yi arayın.",
                    "Bebeği soğuk suyla silmeyin, doktor önermeden ateş düşürücü vermeyin.",
                    "Bebeği fazla giydirmeyin, sıcak ortamdan uzak tutun."
                  ]),
            .init(id: "fever_3_6m_385plus",
                  label: "3–6 aylık + 38.5°C ve üzeri",
                  urgency: .warning,
                  advice: "Aynı gün pediatristinizle iletişime geçmeniz önerilir.",
                  nextSteps: [
                    "Pediatristinizi arayın veya Aile Sağlığı Merkezi'ne gidin.",
                    "Bol sıvı (anne sütü/biberon) verin.",
                    "Doktor onayıyla yaşa uygun parasetamol (örn. Calpol) verilebilir.",
                    "Ateş 39°C üzerine çıkar veya halsizleşirse acile gidin."
                  ]),
            .init(id: "fever_mild",
                  label: "37.5–38°C (hafif)",
                  urgency: .normal,
                  advice: "Hafif ateş enfeksiyona karşı vücudun normal tepkisi olabilir.",
                  nextSteps: [
                    "Her 1–2 saatte tekrar ölçün.",
                    "İnce kıyafet giydirin, oda sıcaklığını 22°C civarına ayarlayın.",
                    "Sıvı alımını artırın.",
                    "12 saat içinde geçmezse veya artarsa doktorla görüşün."
                  ]),
            .init(id: "fever_seizure",
                  label: "Ateşle birlikte havale / titreme",
                  urgency: .emergency,
                  advice: "Ateşli havale (febril konvülziyon) kısa süreli olsa bile ciddi değerlendirilmelidir.",
                  nextSteps: [
                    "112'yi arayın.",
                    "Bebeği yan yatırın, ağzına bir şey sokmayın.",
                    "Hareketleri ve süresini not edin."
                  ])
        ]
    )

    static let kusma = SymptomCategory(
        id: "vomit",
        title: "Kusma",
        icon: "drop.triangle.fill",
        color: .orange,
        prompt: "Bebek bezini ve kıyafetini değiştirdiğinizde gördüklerinize göre seçin.",
        scenarios: [
            .init(id: "vomit_spit",
                  label: "Tükürür gibi ağız kenarından az miktarda",
                  urgency: .normal,
                  advice: "Yenidoğanların büyük çoğunluğunda görülen 'tükürür' (regurgitasyon) — normaldir.",
                  nextSteps: [
                    "Beslemeden sonra 15-20 dk dik tutun, gazını çıkarın.",
                    "Az ama sık besleyin.",
                    "Kilo alımı normalse endişelenmenize gerek yok."
                  ]),
            .init(id: "vomit_projectile",
                  label: "Fışkırır şekilde, her öğünden sonra",
                  urgency: .warning,
                  advice: "Pilor stenozu gibi durumların habercisi olabilir; bugün doktora başvurulmalı.",
                  nextSteps: [
                    "Bugün pediatristinize başvurun.",
                    "Sıvı kaybını izleyin (ıslak bez sayısı, ağız kuruluğu).",
                    "Bebeği susuz bırakmayın — anne sütü/mama vermeye devam edin."
                  ]),
            .init(id: "vomit_green",
                  label: "Yeşil veya sarı (safralı) kusma",
                  urgency: .emergency,
                  advice: "Safralı kusma bağırsak tıkanıklığı (volvulus) işareti olabilir — acil.",
                  nextSteps: [
                    "Hemen acil servise gidin.",
                    "Bir şey yedirmeyin, sadece doktorun söylediği şekilde sıvı verin."
                  ]),
            .init(id: "vomit_blood",
                  label: "Kanlı veya kahve telvesi rengi",
                  urgency: .emergency,
                  advice: "Sindirim sisteminde kanama olabilir — acil değerlendirme şart.",
                  nextSteps: [
                    "112'yi arayın veya acile gidin.",
                    "Renk ve miktarı not edin, mümkünse fotoğraf çekin."
                  ])
        ]
    )

    static let kaka = SymptomCategory(
        id: "stool",
        title: "Kaka / İshal",
        icon: "circle.hexagongrid.fill",
        color: .brown,
        prompt: "Bezin içindeki rengi seçin. Anne sütü alan bebeklerde renk ve kıvam çok değişkendir.",
        scenarios: [
            .init(id: "stool_yellow",
                  label: "Sarı, hardal rengi, sulu (anne sütü)",
                  urgency: .normal,
                  advice: "Anne sütü alan bebeklerde tipik kaka — normaldir.",
                  nextSteps: [
                    "Günde 5+ değişim normaldir.",
                    "Bebek kilo alıyor ve aktifse endişelenmeyin."
                  ]),
            .init(id: "stool_green",
                  label: "Yeşilimsi kaka",
                  urgency: .normal,
                  advice: "Çoğunlukla normaldir (ön süt fazla alınmış olabilir). Anne diyetine bağlı da olabilir.",
                  nextSteps: [
                    "Birkaç gün izleyin.",
                    "Her öğünde tek meme bitene kadar emzirin (arka süt yağlı sütü için).",
                    "Bebekte halsizlik, ateş ya da kanlı kaka eklenirse doktora başvurun."
                  ]),
            .init(id: "stool_white",
                  label: "Beyaz / krem rengi kaka",
                  urgency: .emergency,
                  advice: "Beyaz kaka safra sorunlarının (safra atrezisi) erken belirtisi olabilir — acil.",
                  nextSteps: [
                    "Bugün/yarın mutlaka pediatristinize gidin.",
                    "Bez fotoğrafını saklayın, doktora gösterin.",
                    "İdrar koyu sarıysa bunu da bildirin."
                  ]),
            .init(id: "stool_black",
                  label: "Siyah (yeni doğum mekonyumu hariç)",
                  urgency: .emergency,
                  advice: "İlk haftalardan sonra siyah kaka sindirim sisteminde kanama olabilir.",
                  nextSteps: [
                    "Acil servise gidin.",
                    "Bez örneğini saklayın."
                  ]),
            .init(id: "stool_blood",
                  label: "Kanlı kaka",
                  urgency: .warning,
                  advice: "Az miktar olabilir (anal fissür), ama mutlaka değerlendirilmeli.",
                  nextSteps: [
                    "Bugün pediatristinize başvurun.",
                    "Sürekli/yoğunsa veya bebek halsizse acile gidin."
                  ]),
            .init(id: "stool_diarrhea",
                  label: "Sık ve aşırı sulu (10+ kez/gün)",
                  urgency: .warning,
                  advice: "İshal yenidoğanlarda hızlı dehidratasyon riski taşır.",
                  nextSteps: [
                    "Pediatristinizi arayın.",
                    "Anne sütü/mama vermeye devam edin — kesmeyin.",
                    "Islak bez sayısı 6'nın altına düşerse acile gidin."
                  ])
        ]
    )

    static let beslenme = SymptomCategory(
        id: "feeding",
        title: "Beslenmiyor",
        icon: "drop.fill",
        color: .blue,
        prompt: "Bebeğin beslenme davranışına göre seçin.",
        scenarios: [
            .init(id: "feed_refused_short",
                  label: "1–2 öğün atladı, sonra normale döndü",
                  urgency: .normal,
                  advice: "Tek seferlik beslenme reddi yaygındır.",
                  nextSteps: [
                    "Bebek aktifse ve idrar çıkıyorsa izleyin.",
                    "Bir sonraki öğünü zorlamayın, kendi isteğiyle yapsın.",
                    "Aynı gün içinde tekrar olursa pediatristi arayın."
                  ]),
            nextScenarioFeedingRefuse,
            .init(id: "feed_weak_suck",
                  label: "Emerken yorulup uyuyor / güçsüz",
                  urgency: .warning,
                  advice: "Zayıf emme refleksi enfeksiyon veya başka bir sorun işareti olabilir.",
                  nextSteps: [
                    "Bugün pediatristinize gidin.",
                    "Ne kadar sürdüğünü ve ağırlık değişimini not alın."
                  ]),
            .init(id: "feed_with_cyanosis",
                  label: "Emerken cilt mor/mavi oluyor",
                  urgency: .emergency,
                  advice: "Kalp veya solunum problemi olabilir — acil.",
                  nextSteps: [
                    "112'yi arayın.",
                    "Bebeği dik tutun, soğuktan koruyun."
                  ])
        ]
    )

    private static let nextScenarioFeedingRefuse = SymptomScenario(
        id: "feed_refused_long",
        label: "6+ saat hiç beslenmedi, halsiz",
        urgency: .emergency,
        advice: "Uzun beslenme reddi + halsizlik ciddi durumdur.",
        nextSteps: [
            "Acil servise gidin.",
            "Son beslenme saati, idrar/kaka çıkışı, ateş varsa not edin."
        ]
    )

    static let idrar = SymptomCategory(
        id: "urine",
        title: "Az İdrar",
        icon: "drop.degreesign.fill",
        color: .yellow,
        prompt: "Son 24 saatte ıslak bez sayısına göre seçin (yenidoğanlar günde 6–10 ıslak bez yapar).",
        scenarios: [
            .init(id: "urine_normal",
                  label: "Günde 6+ ıslak bez",
                  urgency: .normal,
                  advice: "Normal sıvı alımı yeterli.",
                  nextSteps: [
                    "Aynı düzeni koruyun, beslenmeye devam edin."
                  ]),
            .init(id: "urine_low",
                  label: "Günde 4–6 arası ıslak bez",
                  urgency: .warning,
                  advice: "Hafif dehidratasyon riski — daha sık besleyin.",
                  nextSteps: [
                    "Beslenme aralıklarını kısaltın.",
                    "Yarına kadar düzelmezse doktora gidin."
                  ]),
            .init(id: "urine_very_low",
                  label: "24 saatte 3 veya daha az ıslak bez",
                  urgency: .emergency,
                  advice: "Belirgin dehidratasyon — acil değerlendirme şart.",
                  nextSteps: [
                    "Acile gidin.",
                    "Bebeğin ağzı kuru, gözleri çökük veya bıngıldağı çökmüş olabilir — bunları not edin."
                  ]),
            .init(id: "urine_dark",
                  label: "İdrar koyu turuncu / kırmızımsı",
                  urgency: .warning,
                  advice: "Dehidratasyon veya idrar yolu enfeksiyonu olabilir.",
                  nextSteps: [
                    "Bugün doktora başvurun.",
                    "Bez örneğini saklayın."
                  ])
        ]
    )

    static let solunum = SymptomCategory(
        id: "breathing",
        title: "Solunum",
        icon: "lungs.fill",
        color: .cyan,
        prompt: "Bebeğin nefes alışını gözlemleyin. Yenidoğanlarda normal hız dakikada 40–60.",
        scenarios: [
            .init(id: "breath_normal",
                  label: "Düzenli, sessiz solunum",
                  urgency: .normal,
                  advice: "Normaldir.",
                  nextSteps: [
                    "Bebek 5–10 saniyelik kısa duraklamalar yapabilir (periyodik solunum) — endişe değil."
                  ]),
            .init(id: "breath_fast",
                  label: "Dakikada 60'tan hızlı solunum",
                  urgency: .emergency,
                  advice: "Takipne — enfeksiyon veya kalp/akciğer sorunu işareti olabilir.",
                  nextSteps: [
                    "Acile gidin veya 112'yi arayın.",
                    "1 dakika boyunca nefes sayısını sayıp not edin."
                  ]),
            .init(id: "breath_grunting",
                  label: "Hırıltılı / inleyerek / burun delikleri açılarak",
                  urgency: .emergency,
                  advice: "Solunum güçlüğü — derhal değerlendirilmeli.",
                  nextSteps: [
                    "112'yi arayın.",
                    "Bebeği dik tutun, soğukta tutmayın."
                  ]),
            .init(id: "breath_apnea",
                  label: "10 saniyeden uzun nefes duraklaması, morarma",
                  urgency: .emergency,
                  advice: "Apne — acil yaşam tehlikesi olabilir.",
                  nextSteps: [
                    "Hemen 112'yi arayın.",
                    "Bebeği uyandırın, gerekirse CPR uygulayın."
                  ])
        ]
    )

    static let ağlama = SymptomCategory(
        id: "crying",
        title: "Aşırı Ağlama",
        icon: "person.crop.circle.badge.exclamationmark.fill",
        color: .pink,
        prompt: "Bebek normalde nasıl sakinleşir? Dindiremediğinizde ne kadar süredir ağlıyor?",
        scenarios: [
            .init(id: "cry_short",
                  label: "Birkaç dakika ağlıyor, sonra sakinleşiyor",
                  urgency: .normal,
                  advice: "Açlık, ıslaklık, gaz veya uyku ihtiyacı olabilir.",
                  nextSteps: [
                    "Bezi kontrol edin, besleyin, kucağa alın.",
                    "Skin-to-skin temas çoğu zaman yardımcı olur."
                  ]),
            .init(id: "cry_colic",
                  label: "Her gün aynı saatlerde 1+ saat, dindirilemez",
                  urgency: .normal,
                  advice: "Bebek koliği olabilir (3 hafta–4 ay arası yaygın). Genellikle 4. ayda geçer.",
                  nextSteps: [
                    "Bebeği sıkıca sarın (kundak), sallayın, beyaz gürültü çalın.",
                    "Annenin diyetinde kafein/süt ürünü olabilir — dene-gözle.",
                    "Geçmiyorsa pediatristle paylaşın."
                  ]),
            .init(id: "cry_long",
                  label: "2+ saat dindirilemeyen ağlama, halsizlik birlikte",
                  urgency: .warning,
                  advice: "Bugün doktora başvurun.",
                  nextSteps: [
                    "Ateş, kusma, az besleniyor mu kontrol edin.",
                    "Bezi açıp deride kızarıklık/sıyrık var mı bakın."
                  ]),
            .init(id: "cry_high_pitch",
                  label: "Tiz, sıradışı, acılı çığlık",
                  urgency: .emergency,
                  advice: "Beyin ya da iç organla ilgili bir sorun olabilir — acil.",
                  nextSteps: [
                    "Acile gidin veya 112'yi arayın.",
                    "Ses, süre ve eşlik eden belirtileri not edin."
                  ])
        ]
    )

    static let uyku = SymptomCategory(
        id: "sleep",
        title: "Letarji / Uyku",
        icon: "moon.zzz.fill",
        color: .indigo,
        prompt: "Bebeğin uyku durumu nasıl?",
        scenarios: [
            .init(id: "sleep_normal",
                  label: "Beslenme için uyanıyor, sonra tekrar uyuyor",
                  urgency: .normal,
                  advice: "0–3 ay arası günde 16–18 saat uyku normaldir.",
                  nextSteps: [
                    "Sırt üstü uyutun, yatakta yumuşak nesne bulundurmayın."
                  ]),
            .init(id: "sleep_hard_to_wake",
                  label: "Beslenme için uyandırmak çok zor",
                  urgency: .warning,
                  advice: "Bugün doktora başvurun.",
                  nextSteps: [
                    "Son beslenme saati ve idrar çıkışını not edin.",
                    "Ateş ölçün."
                  ]),
            .init(id: "sleep_unresponsive",
                  label: "Uyandıramıyorum, gözleri açılmıyor / sönük bakıyor",
                  urgency: .emergency,
                  advice: "Letarji — bilinç bozukluğu acil durumdur.",
                  nextSteps: [
                    "Hemen 112'yi arayın.",
                    "Soluk alıp aldığını kontrol edin.",
                    "Hareket etmediğini, ten renginin değiştiğini not edin."
                  ])
        ]
    )

    static let sarılık = SymptomCategory(
        id: "jaundice",
        title: "Sarılık",
        icon: "sun.max.fill",
        color: .yellow,
        prompt: "Bebeğin cildi ve göz aklarının rengini doğal ışıkta değerlendirin.",
        scenarios: [
            .init(id: "jaund_mild_early",
                  label: "İlk 2 hafta, sadece hafif yüz sararması",
                  urgency: .normal,
                  advice: "Fizyolojik sarılık yenidoğanların %60'ında görülür, çoğu kendi geçer.",
                  nextSteps: [
                    "Bebeği bol besleyin (anne sütü emilmeyi artırır).",
                    "İlk haftada pediatrist kontrolünde takip yeterli.",
                    "Şüphede ışık testi (transkutanöz bilirubin) yaptırın."
                  ]),
            .init(id: "jaund_eyes",
                  label: "Göz akları belirgin sarı",
                  urgency: .warning,
                  advice: "Daha yüksek bilirubin seviyesi olabilir — değerlendirme şart.",
                  nextSteps: [
                    "Bugün pediatristinize gidin.",
                    "Açık alanda göz fotoğrafı çekin, doktora gösterin."
                  ]),
            .init(id: "jaund_persistent",
                  label: "2 haftadan uzun, geçmiyor",
                  urgency: .warning,
                  advice: "Uzun süreli sarılık ileri tetkik gerektirir.",
                  nextSteps: [
                    "Pediatristinizden kan tahlili isteyin.",
                    "Kaka renginin beyaz olmadığından emin olun (öyleyse acil)."
                  ]),
            .init(id: "jaund_severe",
                  label: "Sararma yanı sıra halsizlik, beslenmiyor, ateş",
                  urgency: .emergency,
                  advice: "Ağır sarılık beyin hasarına yol açabilir — acil.",
                  nextSteps: [
                    "Acile gidin.",
                    "Beslenmeye devam edin, bebeği soğukta tutmayın."
                  ])
        ]
    )

    static let ciltVeRenk = SymptomCategory(
        id: "skin",
        title: "Cilt Rengi / Döküntü",
        icon: "hand.raised.fill",
        color: .purple,
        prompt: "Bebeğin cildinde fark ettiğiniz değişikliği seçin.",
        scenarios: [
            .init(id: "skin_blue",
                  label: "Dudaklar, dil veya yüz mavimsi / mor",
                  urgency: .emergency,
                  advice: "Siyanoz — oksijen yetersizliği işareti, acil.",
                  nextSteps: [
                    "Hemen 112'yi arayın.",
                    "Bebek soğukta kalmasın, dik tutun."
                  ]),
            .init(id: "skin_pale",
                  label: "Solgun, gri renkli, soğuk eller-ayaklar",
                  urgency: .warning,
                  advice: "Dolaşım veya enfeksiyon problemi olabilir.",
                  nextSteps: [
                    "Acile başvurun.",
                    "Ateş ölçün, beslenme durumunu not edin."
                  ]),
            .init(id: "skin_rash_normal",
                  label: "Yüzde küçük beyaz/sarı noktalar (milia)",
                  urgency: .normal,
                  advice: "Yenidoğanların %50'sinde görülen milia — normal, kendi geçer.",
                  nextSteps: [
                    "Sıkmayın, kremlemeye gerek yok.",
                    "Genelde 2–4 haftada kaybolur."
                  ]),
            .init(id: "skin_rash_petechiae",
                  label: "Cilt üzerinde basınca kaybolmayan kırmızı/mor noktalar",
                  urgency: .emergency,
                  advice: "Peteşi — menenjit veya kan bozukluğu işareti olabilir.",
                  nextSteps: [
                    "112'yi arayın.",
                    "Şeffaf bardak ile noktalara bastırın — kaybolmuyorsa acil.",
                    "Ateş, halsizlik, beslenme azlığı eşlik ediyorsa hemen acile."
                  ]),
            .init(id: "skin_diaper_rash",
                  label: "Bez bölgesinde kızarıklık (pişik)",
                  urgency: .normal,
                  advice: "Yaygın, çoğunlukla bezin uzun kalmasından olur.",
                  nextSteps: [
                    "Sık bez değişimi, açık hava (mümkün olduğunca).",
                    "Pişik kremi (çinko oksit) sürün.",
                    "5 günde geçmezse veya kabarcık çıkarsa doktora gösterin."
                  ])
        ]
    )
}
