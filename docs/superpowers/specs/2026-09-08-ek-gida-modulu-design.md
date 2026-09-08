# Ek Gıda Modülü — Tasarım Dokümanı

**Tarih:** 2026-09-08
**Durum:** Onaylandı (Oğuz, 2026-09-08)
**Kapsam:** Uygulamanın yaş çerçevesini 0–6 aydan 0–24 aya taşıma + tamamlayıcı beslenme (ek gıda) takibi

---

## 1. Problem

Baby Care 0–6 ay yenidoğan takibi için tasarlandı. Bebek 6 ayını doldurduğunda uygulama kullanılamaz hâle geliyor: ek gıda kaydedilecek yer yok, aşı takvimi bitiyor, gelişim rehberi "kapsam dışı" diyor ve büyüme grafiği sessizce yanlış sonuç üretiyor. Kullanıcı tam da ek gıdaya geçiş gibi kaygı yoğun bir dönemde uygulamayı bırakmak zorunda kalıyor.

## 2. Alınan kararlar

| Karar | Seçim | Gerekçe |
|---|---|---|
| K-01 Faz 1 kapsamı | Yaş genişletmesi (A) + ek gıda çekirdeği (B) + kritik güvenlik ekranları (D1, D2) | Dikey dilim: uçtan uca çalışan ince bir dilim. Menü planlayıcı ve tarif kartları ikinci faza. |
| K-02 Alerjen çizgisi | Güncel uluslararası konsensüs (ESPGHAN, AAP 2023, EAACI, NIAID) esas; TÜBER 2022'nin 3–5 gün önerisi "isteğe bağlı gözlem aralığı" notu | Erken tanıtımın koruyucu etkisi için kanıt güçlü (LEAP). Her iki kaynak da ekranda linklenir. |
| K-03 Beslenme yöntemi | Hem geleneksel püre hem BLW; kullanıcı seçer | Besin kütüphanesinde her besin iki sunum biçimiyle gösterilir. Solid Starts'ın farklılaştığı nokta bu. |
| K-04 Konumlandırma | Ücretsiz kalır, uygulama 0–24 ay olarak yeniden konumlanır | Mevcut gizlilik odaklı, reklamsız konumlandırma korunur. StoreKit/paywall yükü yok. |
| K-05 Ek gıda veri modeli | `FeedingRecord`'u genişletmek yerine ayrı `SolidFoodRecord` | Canlı App Store verisinde migration riski alınmaz. Ayrıntı: bölüm 4. |

## 3. Düzeltilecek mevcut hatalar

Bunlar ek gıdadan bağımsız ama aynı dosyalara dokunduğu için bu fazda düzeltilir.

| # | Yer | Sorun | Doğrulama |
|---|---|---|---|
| H-1 | `Core/Models/WHOPercentiles.swift:128` | `percentileBand` ayı `min(rows.count-1, ageMonths)` ile clamp ediyor; tablo 0–6 ay. 14 aylık bebeğin kilosu 6. ay eğrisiyle karşılaştırılıyor, hata vermeden yanlış persentil basıyor. | Kod okuması |
| H-2 | `Core/Models/VaccineCatalog.swift` | `kpa_6m` ("KPA 3. doz, 6. ay") tanımlı. Resmi 2025 takviminde KPA şeması 2+1: 2. ay, 4. ay, 12. ay rapel. 6. ayda KPA yok. | asi.saglik.gov.tr 2025 takvim PDF, tablo doğrudan çıkarıldı |
| H-3 | `Core/Models/VaccineCatalog.swift` | 9. ay sonu KKK ek dozu takvimde var, uygulamada yok. | Aynı PDF |
| H-4 | `Core/Services/FeedingCalculator.swift:64` | 150–180 ml/kg sabiti tüm yaşlara uygulanıyor. Ek gıda başlayınca süt ihtiyacı düşer; hesap fazla çıkıyor. | Kod okuması + TÜBER 2022 |

**H-2 migration notu:** `kpa_6m` kaldırılınca mevcut kullanıcılarda öksüz `VaccinationRecord` kalır — `definition` nil döner ve UI ham id gösterir (`DashboardView.swift:305`, `rec.definition?.shortName ?? rec.vaccineDefinitionID`). Tek seferlik temizlik adımı gerekir: `vaccineDefinitionID == "kpa_6m"` olan ve `completedDate == nil` olan kayıtlar silinir; tamamlanmış olanlar korunur (kullanıcı gerçekten yaptırmış olabilir) ve katalogda `isRetired` işaretli bir tanım olarak kalır.

## 4. Mimari yaklaşım

Ek gıda kaydının nereye oturacağı için üç seçenek değerlendirildi:

1. **`FeedingRecord`'u genişlet** (`FeedingType`'a `.solid` ekle). Takip/PDF/özet/backup zaten bu modeli biliyor. Ama `side`, `amountML`, `durationSeconds` katı gıda için anlamsız; model şişer ve canlı veride şema değişikliği riski doğar.
2. **Ayrı `SolidFoodRecord`** — seçilen. `FeedingRecord`'a hiç dokunulmaz, 1.4.1 kullanıcı verisi risksiz kalır. SwiftData'da yeni `@Model` eklemek lightweight migration ile otomatik. Maliyeti: takip özeti, PDF, backup ve haftalık özet olmak üzere dört noktada birleştirme kodu.
3. **Birleşik `NutritionEvent`** soyutlaması. Uzun vadede en temiz ama mevcut kullanıcı verisinin migration'ını gerektirir — App Store'da canlı bir uygulamada kabul edilemez risk. YAGNI.

**Seçim: 2.** Birleştirme maliyeti dört küçük noktada ve geri alınabilir; migration riski geri alınamaz.

## 5. Veri modeli

İki yeni `@Model`. Mevcut modellerin hiçbiri değişmiyor.

```
SolidFoodRecord
  id: UUID (unique)
  babyID: UUID
  servedAt: Date
  foodIDs: [String]          — FoodCatalog referansları (bir öğünde birden çok besin)
  customFoodName: String?    — katalog dışı besin
  methodRaw: String          — puree | fingerFood | familyMeal
  amountRaw: String          — tasted | some | most | all
  reactionRaw: String        — loved | neutral | refused | adverse
  isFirstTry: Bool
  notes: String?
  createdAt, updatedAt: Date

AllergenIntroduction
  id: UUID (unique)
  babyID: UUID
  allergenRaw: String        — 9 major alerjenden biri
  statusRaw: String          — notIntroduced | introduced | tolerated | reacted
  firstTriedAt: Date?
  lastServedAt: Date?
  reactionNotes: String?
  createdAt, updatedAt: Date
```

**Miktar neden ml değil:** 6–24 ay aralığında ebeveyn gerçekte ml ölçmüyor. `tasted / some / most / all` hem doldurulabilir hem anlamlı. Süt tarafındaki ml takibi `FeedingRecord`'da olduğu gibi kalır.

**`lastServedAt` neden var:** AAP 2023, tolere edilen alerjenin düzenli sürdürülmesini öneriyor — tek tadım yeterli değil. Bu alan sayesinde uygulama "yumurta 3 haftadır verilmedi" diyebilir. İncelenen hiçbir rakip uygulama bunu yapmıyor; modülün ayırt edici özelliği.

## 6. Katalog verileri

### 6.1 Yeni: `FoodCatalog`

Yaklaşık 130 besin, Türk mutfağına uygun. Her kayıt:

- `id`, `name`, `group` (sebze / meyve / tahıl / protein / süt ürünü / baklagil / yağ)
- `minAgeMonths` — en erken önerilen yaş
- `prepPuree`, `prepFingerFood`, `prepFamilyMeal` — üç sunum biçimi metni (K-03 gereği)
- `chokingRisk` (low / medium / high) + `safePrepNote` — örn. üzüm: yüksek risk, uzunlamasına dörde bölünür
- `allergen: Allergen?` — major alerjen bayrağı
- `isIronRich`, `isVitaminCRich` — demir emilimi eşleştirmesi için
- `ageBarrier: AgeBarrier?` — yasak niteliğindeki yaş sınırı. `AgeBarrier` = `(minAgeMonths: Int, reason: String, sourceURL: String)`. Kapsanan durumlar: bal 12 ay (infantil botulizm), tuz 12 ay, ilave şeker 24 ay, inek sütü ana içecek olarak 12 ay, meyve suyu 12 ay (1–3 yaş arası verilirse günde en fazla 120 ml). `minAgeMonths` alanından farkı: `minAgeMonths` "bu yaştan önce önerilmez", `ageBarrier` "bu yaştan önce verilmez" — UI'da farklı ağırlıkta gösterilir.

### 6.2 Yeni: `AllergenCatalog`

9 major alerjen (FDA "Big 9"): süt, yumurta, yer fıstığı, ağaç yemişleri, buğday, soya, susam, balık, kabuklu deniz ürünleri. Her biri için tanıtım yaşı, güvenli sunum biçimi, dikkat notu ve kaynak linki.

Tanıtım kuralı (K-02): ~6. ayda, 4 tamamlanmış aydan önce değil, geciktirilmeden. Yumurta iyi pişmiş; yer fıstığı ve tahin su/yoğurt/püre ile inceltilmiş — bütün fındık ve koyu ezme kaşığı boğulma tehlikesi. Yüksek riskli bebekte (ağır egzama ve/veya yumurta alerjisi) uzman değerlendirmesi notu gösterilir; uygulama protokol önermez.

### 6.3 Genişleyen: `WHOPercentiles`

7–24 ay satırları eklenir (kilo, boy, baş çevresi; kız/erkek; P3/P15/P50/P85/P97). Kaynak: WHO Child Growth Standards genişletilmiş tablolar.

`percentileBand` imzası `String` yerine `String?` döner; tablo dışı ay için `nil`. Çağıran taraf "veri yok" gösterir. H-1 böyle kapanır — sessiz yanlış yerine görünür boşluk.

### 6.4 Genişleyen: `VaccineCatalog`

`firstSixMonths` → `schedule`. 2025 Ulusal Çocukluk Dönemi Aşılama Takvimi (asi.saglik.gov.tr PDF'inden doğrudan çıkarıldı):

| Zaman | Aşılar |
|---|---|
| Doğum | Hep-B I |
| 2. ay sonu | BCG I, KPA I, DaBT-İPA-Hib-HepB I |
| 4. ay sonu | KPA II, DaBT-İPA-Hib-HepB II |
| 6. ay sonu | DaBT-İPA-Hib-HepB III, OPA I |
| 9. ay sonu | KKK ek doz |
| 12. ay sonu | KPA rapel, Suçiçeği I, KKK I |
| 18. ay sonu | DaBT-İPA-Hib-HepB rapel, OPA II, Hep-A I |
| 24. ay sonu | Hep-A II |

24 ay üstü (kapsam dışı, katalogda yer almaz): 48. ay KKK II + DaBT-İPA rapel + Suçiçeği II, 13 yaş Td rapel. Suçiçeği 2. dozu 1 Eylül 2026'da takvime eklendi.

### 6.5 Genişleyen: `GuideCatalog`

Yeni aşamalar: 6–8 ay, 9–11 ay, 12–15 ay, 15–18 ay, 18–24 ay. Mevcut `stage_26_plus` aşamasındaki "Uygulamanın hedef kapsamı dışında" metni kaldırılır.

`GuideStage.feedingTips` alanı ek gıda dönemi için doğrulanmış verilerle doldurulur:

| Dönem | Kıvam | Öğün | Porsiyon | Ek gıdadan enerji |
|---|---|---|---|---|
| 6–8 ay | Püre → ezme; ~8. ayda parmak besin | 2–3 ana + 1–2 ara | ~125 ml | ~200 kcal/gün |
| 9–11 ay | İnce doğranmış, elle kavranan | 3–4 ana + 1–2 ara | ~125 ml | ~300 kcal/gün |
| 12–24 ay | Aile yemeği (doğranmış) | 3–4 ana + 1–2 ara | ~180 ml | ~550 kcal/gün |

Sabit kurallar: anne sütü 2 yaşa kadar sürer; 6. aydan itibaren demir kaynağı (kırmızı et, tavuk, balık, yumurta) günlük hedeftir; bitkisel demir C vitamini içeren besinle birlikte sunulur.

### 6.6 Genişleyen: `FirstAidCatalog` ve `SymptomCatalog`

- `FirstAidCatalog`: bebek ve çocuk boğulma müdahalesi; öğürme (gag) ile boğulma (choking) ayrımı — ebeveynin en sık karıştırdığı ve paniklediği nokta.
- `SymptomCatalog`: alerjik reaksiyon ve anafilaksi kategorisi. Hafif tek sistem belirtisi ile anafilaksi kriterleri ayrı ayrı; anafilakside 112 ve adrenalin vurgusu, antihistaminiğin adrenalin yerine geçmediği notu.

## 7. Navigasyon

Tab bar 5 sekmede kalır — yeni tab eklenmez.

- **Takip sekmesi:** `summaryRow`'a dördüncü kart "Ek Gıda" (yalnız bebek ≥6 ay). `quickAddRow`'a katı gıda ekleme butonu. Gün listesinde `SolidFoodRecord` satırları.
- **Bebek sekmesi:** "Detaylar" bölümüne "Ek Gıda" satırı (≥6 ay). Açılan ekran üç bölüm: besin kütüphanesi (arama + yaş/grup/alerjen filtresi), alerjen paneli, aşama rehberi.
- **Ana sayfa:** bebek 6. ayı doldurduğunda "ek gıdaya geçiş" kartı. Kart kullanıcı kapatana kadar görünür; kapatma durumu `@AppStorage("solidsIntroCardDismissed_<babyID>")` ile bebek başına saklanır (çoklu bebek desteği var, global anahtar yanlış olur). `weeklyTip` 24 aya kadar genişler (şu an `default` dalında tek cümlede bitiyor).

## 8. Yaş kapıları

Yeni `BabyStage` enum'u tek kaynak olur:

```
enum BabyStage { case newborn        // < 6 ay
                 case complementary  // 6–12 ay
                 case toddler }      // 12–24 ay
```

`Baby` üzerinde hesaplanan bir property olarak sunulur. UI'ya dağılacak `ageInMonths >= 6` kontrolleri yerine tek yerden okunur; ileride eşik değişirse tek dosya değişir.

## 9. Güvenlik ve tıbbi içerik sınırı

- Her besin kartında boğulma riski rozeti ve güvenli hazırlama talimatı.
- Yaş bariyerli besin seçildiğinde **engelleme değil uyarı**. Bu bir takip aracı, hakem değil; kullanıcı yine de kaydedebilir.
- `reaction == .adverse` seçilirse alerjik reaksiyon / anafilaksi ekranına doğrudan kısayol.
- Alerjen içeriğinde iki kaynak yan yana: uluslararası konsensüs esas, TÜBER'in 3–5 gün önerisi isteğe bağlı gözlem aralığı notu olarak. Her ikisi de tıklanabilir resmi link — 1.4.1'de yerleşen desen.
- Mevcut "Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz" ibaresi her yeni ekranda tekrarlanır.
- Uygulama tanı koymaz, doz önermez, alerji protokolü yürütmez. Yüksek riskli bebekte uzman değerlendirmesine yönlendirir.

## 10. Entegrasyon noktaları

| Dosya | Değişiklik |
|---|---|
| `Baby_CareApp.swift` | `sharedModelContainer` şemasına `SolidFoodRecord` ve `AllergenIntroduction` |
| `Core/Services/DataBackupService.swift` | `currentVersion` → 2. İki yeni alan da **optional**: `let solidFoods: [SolidFoodExport]?` ve `let allergenIntroductions: [AllergenIntroductionExport]?`. Zorunlu yapılırsa v1 yedekleri `try? decode` ile nil döner ve "dosya bozuk" hatası verir — mevcut kullanıcının yedeği geri yüklenemez hâle gelir. Import tarafında `?? []` ile karşılanır. |
| `Core/Services/BabyDeleteService.swift` | Bebek silinince iki yeni model de silinir |
| `Core/Services/PDFReportGenerator.swift`, `Features/Profile/PDFReportView.swift` | Rapora ek gıda özeti: denenen besin sayısı, alerjen durum tablosu |
| `Core/Services/WeeklySummaryCalculator.swift` | Haftalık özete ek gıda öğün sayısı ve yeni denenen besinler |
| `Core/Services/FeedingCalculator.swift` | Yaşa duyarlı hesap: 6 ay üstünde süt hedefi düşer, ek gıdadan gelen enerji ayrı gösterilir (H-4) |
| `docs/APP_STORE_TR.md`, `docs/APP_STORE_EN.md` | Altyazı, açıklama ve anahtar kelimeler 0–24 aya güncellenir |

## 11. Test stratejisi

- **Katalog bütünlüğü:** `FoodCatalog`, `AllergenCatalog`, `VaccineCatalog`, `GuideCatalog` — boş zorunlu alan yok, yaş sıralaması tutarlı, `GuideCatalog` aşamaları arasında boşluk/çakışma yok, her alerjen bayrağı `AllergenCatalog`'da karşılık buluyor.
- **`percentileBand` sınır testleri:** 0, 6, 7, 24, 25 ay — 25. ayda `nil` dönmeli.
- **Yedek uyumluluğu:** v1 formatındaki bir JSON yedeğinin v2 kodla hatasız import edildiği testi. Bu, bölüm 10'daki optional kararının regresyon koruması.
- **`VaccinationScheduler`:** doğum tarihinden 9/12/18/24. ay kayıtlarının doğru üretildiği; `kpa_6m` üretilmediği.

## 12. Kapsam dışı (bu faz)

- C2 haftalık menü / öğün planlayıcı
- C3 tarif kartları
- E bloğu: diş çıkarma takibi, gelişim mihenk taşı kontrol listesi, semptom kataloğunun ek gıda dışı genişletmesi (ateşli havale, kabızlık, döküntü)
- Ücretlendirme, StoreKit, paywall (K-04)

Aşama rehberi (C1) kapsam içinde — `GuideCatalog` genişletmesinin parçası olarak geliyor.

## 13. Riskler

| Risk | Etki | Azaltma |
|---|---|---|
| İçerik hacmi (~130 besin × 3 sunum biçimi + 9 alerjen + 5 gelişim aşaması) | Plan süresinin çoğunu içerik yazımı yer | Besin kütüphanesi ilk turda ~60 çekirdek besinle çıkar, kalanı ikinci turda eklenir; model ve UI değişmez |
| Medikal içerik App Review'da sorgulanabilir | Reddedilme veya bilgi talebi | Her ekranda kaynak linki + sorumluluk ibaresi; uygulama tanı/doz/protokol sunmuyor. `APP_STORE_REVIEW_NOTES.md` güncellenir |
| TÜBER 2022 ile uluslararası konsensüs çelişkisi kullanıcıyı şaşırtabilir | Güven kaybı | İki kaynak yan yana ve gerekçeli sunulur; hangisinin ne dediği açıkça yazılır, biri gizlenmez |
| `kpa_6m` temizliği mevcut kullanıcı verisine dokunuyor | Veri kaybı algısı | Yalnız tamamlanmamış kayıtlar silinir; tamamlanmışlar korunur |

## 14. Kaynaklar

**Türkiye — resmi**
- Türkiye Beslenme Rehberi (TÜBER) 2022 — https://hsgm.saglik.gov.tr/depo/birimler/saglikli-beslenme-ve-hareketli-hayat-db/Dokumanlar/Rehberler/Turkiye_Beslenme_Rehber_TUBER_2022_min.pdf
- Bebek, Çocuk, Ergen İzlem Protokolleri — https://hsgm.saglik.gov.tr/depo/birimler/cocuk-ergen-sagligi-db/Dokumanlar/Kitaplar/Bebek_Cocuk_Ergen_Izlem_Protokolleri_2018.pdf
- Ulusal Çocukluk Dönemi Aşılama Takvimi 2025 — https://asi.saglik.gov.tr/depo/2025/asi_takvimi/asi_takvimi_2025.pdf
- D Vitamini Programı — https://hsgm.saglik.gov.tr/tr/beslenme-programlari/d-vitamini-eksikligi-onleme-kontrol-programi.html
- Demir Gibi Türkiye Programı — https://hsgm.saglik.gov.tr/tr/beslenme-programlari/demir-gibi-turkiye.html

**Uluslararası**
- WHO Complementary Feeding Guideline 2023 (6–23 ay) — https://iris.who.int/bitstream/handle/10665/373358/9789240081864-eng.pdf
- WHO Child Growth Standards — https://www.who.int/tools/child-growth-standards
- AAP, Updates in Food Allergy Prevention in Children (2023) — https://publications.aap.org/pediatrics/article/152/5/e2023062836/194356/Updates-in-Food-Allergy-Prevention-in-Children
- ESPGHAN Infant Feeding Guidance Summary — https://www.espghan.org/dam/jcr:ea5c9b57-9315-44b7-b9a0-149511b96654/ESPGHAN%20Infant%20Feeding%20Campaign%20-%20Guidance%20Summary.pdf
- EAACI Food Allergy Prevention Guideline (2020 update) — https://eaaci.org/guidelines-position-papers/eaaci-guideline-preventing-the-development-of-food-allergy-in-infants-and-young-children-2020-update/
- NIAID Peanut Allergy Prevention Guidelines — https://www.niaid.nih.gov/sites/default/files/peanut-allergy-prevention-guidelines-clinician-summary.pdf
- AAP Allergy and Anaphylaxis Emergency Plan — https://downloads.aap.org/HC/AAP_Allergy_and_Anaphylaxis_Emergency_Plan.pdf

Aşı takvimi verisi resmi PDF tablosundan doğrudan çıkarılarak doğrulandı; Perplexity ve web arama sonuçları 12. ve 18. ay içerikleri konusunda çelişiyordu, resmi PDF esas alındı.
