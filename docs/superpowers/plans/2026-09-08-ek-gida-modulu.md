# Ek Gıda Modülü Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Baby Care'i 0–6 ay kapsamından 0–24 ay kapsamına taşımak ve tamamlayıcı beslenme (ek gıda) takibi eklemek.

**Architecture:** Ek gıda için `FeedingRecord`'a dokunmadan iki yeni SwiftData modeli (`SolidFoodRecord`, `AllergenIntroduction`) eklenir — canlı App Store verisinde şema migration riski alınmaz. Yaşa bağlı davranış tek bir `BabyStage` enum'undan okunur. Statik içerik (besin kütüphanesi, alerjenler, aşı takvimi, gelişim aşamaları) mevcut katalog desenini izleyerek `Core/Models/` altında `enum` sabitleri olarak yaşar.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, Swift Testing (`import Testing`, XCTest değil), Swift Charts. iOS deployment target 26.5. Xcode projesi `PBXFileSystemSynchronizedRootGroup` kullanır — **klasöre eklenen yeni `.swift` dosyaları projeye otomatik dahil olur, `project.pbxproj` elle düzenlenmez.**

**Spec:** `docs/superpowers/specs/2026-09-08-ek-gida-modulu-design.md`

## Global Constraints

- **Dil:** Tüm kullanıcıya görünen metinler Türkçe. Kod, tip ve değişken adları İngilizce (mevcut konvansiyon). Yorumlar Türkçe.
- **Emoji yasak:** Kullanıcıya görünen hiçbir yüzeyde emoji kullanılmaz; SF Symbols ikonları kullanılır.
- **Tıbbi sınır:** Uygulama tanı koymaz, doz önermez, alerji protokolü yürütmez. Her yeni tıbbi içerik ekranında (a) tıklanabilir resmi kaynak linki ve (b) "Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz." ibaresi bulunur. Desen: `Features/Guide/GuideView.swift:81`.
- **Yaş bariyeri davranışı:** Yaşına uygun olmayan besin seçildiğinde kayıt **engellenmez**, uyarı gösterilir. Uygulama takip aracıdır, hakem değil.
- **Alerjen çizgisi (K-02):** Güncel uluslararası konsensüs (ESPGHAN / AAP 2023 / EAACI / NIAID) esas alınır — alerjenler geciktirilmez, ~6. ayda tanıtılır. TÜBER 2022'nin "3–5 gün arayla" önerisi gizlenmez, "isteğe bağlı gözlem aralığı" notu olarak gösterilir.
- **Yaş kapsamı:** Kataloglar 0–24 ayı kapsar. 24 ay üstü veri (48. ay aşıları, 13 yaş Td) katalogda yer almaz.
- **Simülatör (ilk kez, oturum başına bir defa):** `OS=26.5` belirtmek zorunludur — bu makinede iOS 26.5 ve iOS 27.0 altında "iPhone 17 Pro" adında iki cihaz var ve `OS` verilmezse xcodebuild test runner'ı başlatamıyor ("Simulator device failed to launch ... No such process"). Simülatörü önceden boot etmek ilk çalıştırmayı hızlandırır:
  ```bash
  xcrun simctl boot DFD63213-2F6D-4DAD-94EF-9D00BEA85600
  xcrun simctl bootstatus DFD63213-2F6D-4DAD-94EF-9D00BEA85600 -b
  ```
- **Test komutu (tümü):**
  ```bash
  xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
    -only-testing:"Baby CareTests" -quiet
  ```
  Doğrulandı: 2026-09-08 tarihinde mevcut boş test paketiyle çalıştırıldı, PASS. Temiz build ~10 dakika, sonraki çalıştırmalar ~16 saniye.
- **Test komutu (tek test):** yukarıdakine `-only-testing:"Baby CareTests/<SuiteAdı>/<testAdı>"` ekle.
- **Modül adı:** Test dosyalarında `@testable import Baby_Care` (boşluk alt çizgiye dönüşür).
- **Commit:** Her görev sonunda tek commit, Türkçe mesaj, `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` satırıyla biter.

---

## File Structure

**Yeni dosyalar**

| Dosya | Sorumluluk |
|---|---|
| `Baby Care/Core/Models/BabyStage.swift` | Yaş kapısı enum'u ve `Baby` uzantısı |
| `Baby Care/Core/Models/Allergen.swift` | 9 major alerjen enum'u + `AllergenCatalog` |
| `Baby Care/Core/Models/FoodCatalog.swift` | Besin kütüphanesi verisi ve arama/filtre yardımcıları |
| `Baby Care/Core/Models/SolidFoodRecord.swift` | Katı gıda öğün kaydı modeli + yardımcı enum'lar |
| `Baby Care/Core/Models/AllergenIntroduction.swift` | Alerjen tanıtım durumu modeli |
| `Baby Care/Core/Services/SolidFoodService.swift` | Katı gıda kaydetme + alerjen durumu otomatik güncelleme |
| `Baby Care/Core/Services/VaccinationMigration.swift` | Tek seferlik `kpa_6m` temizliği |
| `Baby Care/Features/SolidFood/SolidFoodAddSheet.swift` | Öğün ekleme/düzenleme formu |
| `Baby Care/Features/SolidFood/SolidFoodView.swift` | Ek Gıda ana ekranı (3 sekme) |
| `Baby Care/Features/SolidFood/FoodLibraryView.swift` | Besin kütüphanesi listesi + filtre |
| `Baby Care/Features/SolidFood/FoodDetailView.swift` | Tek besin kartı |
| `Baby Care/Features/SolidFood/AllergenPanelView.swift` | 9 alerjen durum paneli |
| `Baby CareTests/BabyStageTests.swift` … `BackupCompatibilityTests.swift` | Görev başına bir test dosyası |

**Değişen dosyalar**

`Core/Models/WHOPercentiles.swift` (7–24 ay + nil dönüş), `Core/Models/VaccineCatalog.swift` (0–24 ay), `Core/Models/GuideCatalog.swift` (6–24 ay aşamaları), `Core/Models/FirstAidCatalog.swift` (boğulma), `Core/Models/SymptomCatalog.swift` (anafilaksi), `Core/Services/VaccinationScheduler.swift`, `Core/Services/FeedingCalculator.swift`, `Core/Services/BabyDeleteService.swift`, `Core/Services/DataBackupService.swift`, `Core/Services/WeeklySummaryCalculator.swift`, `Core/Services/PDFReportGenerator.swift`, `Baby_CareApp.swift`, `Features/Growth/GrowthView.swift`, `Features/Tracking/TrackingView.swift`, `Features/Home/DashboardView.swift`, `Features/Profile/BabyProfileView.swift`, `docs/APP_STORE_TR.md`, `docs/APP_STORE_EN.md`.

---

## Task 1: BabyStage yaş kapısı

Bütün yaşa bağlı davranışın tek kaynağı. Sonraki her görev buna dayanır, o yüzden ilk sırada.

**Files:**
- Create: `Baby Care/Core/Models/BabyStage.swift`
- Test: `Baby CareTests/BabyStageTests.swift`

**Interfaces:**
- Consumes: `Baby` modeli (`Core/Models/Baby.swift`), `Baby.ageInMonths`
- Produces: `enum BabyStage { case newborn, complementary, toddler }`, `BabyStage.forAgeMonths(_ months: Int) -> BabyStage`, `Baby.stage: BabyStage`, `BabyStage.isSolidFoodAge: Bool`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/BabyStageTests.swift`:

```swift
import Testing
import Foundation
@testable import Baby_Care

struct BabyStageTests {

    @Test func newbornUnderSixMonths() {
        #expect(BabyStage.forAgeMonths(0) == .newborn)
        #expect(BabyStage.forAgeMonths(5) == .newborn)
    }

    @Test func complementaryFromSixToTwelveMonths() {
        #expect(BabyStage.forAgeMonths(6) == .complementary)
        #expect(BabyStage.forAgeMonths(11) == .complementary)
    }

    @Test func toddlerFromTwelveMonths() {
        #expect(BabyStage.forAgeMonths(12) == .toddler)
        #expect(BabyStage.forAgeMonths(24) == .toddler)
        #expect(BabyStage.forAgeMonths(36) == .toddler)
    }

    @Test func solidFoodAgeStartsAtSixMonths() {
        #expect(BabyStage.forAgeMonths(5).isSolidFoodAge == false)
        #expect(BabyStage.forAgeMonths(6).isSolidFoodAge == true)
        #expect(BabyStage.forAgeMonths(20).isSolidFoodAge == true)
    }

    @Test func babyExposesStageFromBirthDate() {
        let eightMonthsAgo = Calendar.current.date(byAdding: .month, value: -8, to: .now)!
        let baby = Baby(name: "Test", birthDate: eightMonthsAgo)
        #expect(baby.stage == .complementary)
    }

    @Test func negativeAgeIsTreatedAsNewborn() {
        #expect(BabyStage.forAgeMonths(-1) == .newborn)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/BabyStageTests" -quiet
```

Beklenen: derleme hatası — `cannot find 'BabyStage' in scope`.

- [ ] **Step 3: Write minimal implementation**

`Baby Care/Core/Models/BabyStage.swift`:

```swift
import Foundation

/// Bebeğin bakım dönemi. Yaşa bağlı tüm UI kapıları ve içerik seçimleri
/// buradan okunur — `ageInMonths >= 6` kontrolünün view'lara dağılmaması için.
enum BabyStage: String, CaseIterable, Sendable {
    case newborn        // 0–6 ay: yalnız anne sütü / mama
    case complementary  // 6–12 ay: ek gıdaya geçiş
    case toddler        // 12 ay ve üzeri

    var localizedTitle: String {
        switch self {
        case .newborn:       return "Yenidoğan (0–6 ay)"
        case .complementary: return "Ek gıda dönemi (6–12 ay)"
        case .toddler:       return "Oyun çocuğu (12–24 ay)"
        }
    }

    /// Ek gıda özelliklerinin görünür olup olmadığı.
    /// DSÖ ve TÜBER 2022: tamamlayıcı beslenme 6. ay dolunca başlar.
    var isSolidFoodAge: Bool {
        self != .newborn
    }

    static func forAgeMonths(_ months: Int) -> BabyStage {
        switch months {
        case ..<6:   return .newborn
        case 6..<12: return .complementary
        default:     return .toddler
        }
    }
}

extension Baby {
    var stage: BabyStage {
        BabyStage.forAgeMonths(ageInMonths)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Aynı komut. Beklenen: 6 test PASS.

- [ ] **Step 5: Commit**

```bash
git add "Baby Care/Core/Models/BabyStage.swift" "Baby CareTests/BabyStageTests.swift"
git commit -m "feat: BabyStage yaş kapısı enum'u

Yaşa bağlı davranışın tek kaynağı. View'lara dağılacak
ageInMonths >= 6 kontrolleri yerine tek yerden okunur.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 2: WHO persentil 7–24 ay ve clamp hatasının düzeltilmesi (H-1)

Şu an `percentileBand` ayı `min(rows.count-1, ageMonths)` ile kırpıyor; tablo 0–6 ay olduğu için 14 aylık bebeğin kilosu 6. ay eğrisiyle karşılaştırılıp hata vermeden yanlış persentil basıyor.

**Files:**
- Modify: `Baby Care/Core/Models/WHOPercentiles.swift`
- Modify: `Baby Care/Features/Growth/GrowthView.swift:151` (chartXScale), `:184` (percentileBand çağrısı)
- Test: `Baby CareTests/WHOPercentileTests.swift`

**Interfaces:**
- Consumes: `WHOPercentiles.Metric`, `WHOPercentiles.Sex`, `WHOPercentiles.Row` (mevcut, değişmiyor)
- Produces: `WHOPercentiles.percentileBand(metric:sex:ageMonths:value:) -> String?` (dönüş tipi `String`'ten `String?`'a değişir), `WHOPercentiles.maxAgeMonths: Int` (= 24)

- [ ] **Step 1: Write the failing test**

`Baby CareTests/WHOPercentileTests.swift`:

```swift
import Testing
@testable import Baby_Care

struct WHOPercentileTests {

    @Test(arguments: [
        (WHOPercentiles.Metric.weight, WHOPercentiles.Sex.female),
        (.weight, .male), (.height, .female), (.height, .male),
        (.head, .female), (.head, .male)
    ])
    func everyTableCoversZeroToTwentyFourMonths(
        metric: WHOPercentiles.Metric, sex: WHOPercentiles.Sex
    ) {
        let rows = WHOPercentiles.data(for: metric, sex: sex)
        #expect(rows.count == 25)
        #expect(rows.first?.month == 0)
        #expect(rows.last?.month == 24)
        // Aylar tekrarsız ve artan sırada
        #expect(rows.map(\.month) == Array(0...24))
    }

    @Test(arguments: [
        (WHOPercentiles.Metric.weight, WHOPercentiles.Sex.female),
        (.weight, .male), (.height, .female), (.height, .male),
        (.head, .female), (.head, .male)
    ])
    func percentilesAreMonotonicWithinEachRow(
        metric: WHOPercentiles.Metric, sex: WHOPercentiles.Sex
    ) {
        for row in WHOPercentiles.data(for: metric, sex: sex) {
            #expect(row.p3 < row.p15, "ay \(row.month): p3 < p15 değil")
            #expect(row.p15 < row.p50, "ay \(row.month): p15 < p50 değil")
            #expect(row.p50 < row.p85, "ay \(row.month): p50 < p85 değil")
            #expect(row.p85 < row.p97, "ay \(row.month): p85 < p97 değil")
        }
    }

    @Test func growsMonotonicallyAcrossMonths() {
        // Kilo ve boy medyanı yaşla artar; küçülme veri hatasıdır.
        for (metric, sex) in [(WHOPercentiles.Metric.weight, WHOPercentiles.Sex.female),
                              (.weight, .male), (.height, .female), (.height, .male)] {
            let rows = WHOPercentiles.data(for: metric, sex: sex)
            for (prev, next) in zip(rows, rows.dropFirst()) {
                #expect(next.p50 > prev.p50, "\(metric) \(sex): ay \(next.month) medyanı düşmüş")
            }
        }
    }

    @Test func returnsNilBeyondTableRange() {
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .female, ageMonths: 25, value: 12.0
        )
        #expect(band == nil)
    }

    @Test func returnsNilForNegativeAge() {
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .male, ageMonths: -1, value: 3.0
        )
        #expect(band == nil)
    }

    @Test func classifiesMedianValueAsNormalRange() {
        let rows = WHOPercentiles.data(for: .weight, sex: .male)
        let month12 = rows.first { $0.month == 12 }!
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .male, ageMonths: 12, value: month12.p50
        )
        #expect(band == "15–85. persentil (normal aralık)")
    }

    @Test func classifiesBelowThirdPercentile() {
        let rows = WHOPercentiles.data(for: .weight, sex: .female)
        let month18 = rows.first { $0.month == 18 }!
        let band = WHOPercentiles.percentileBand(
            metric: .weight, sex: .female, ageMonths: 18, value: month18.p3 - 0.5
        )
        #expect(band == "< 3. persentil")
    }

    @Test func maxAgeMonthsIsTwentyFour() {
        #expect(WHOPercentiles.maxAgeMonths == 24)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/WHOPercentileTests" -quiet
```

Beklenen: derleme hatası (`maxAgeMonths` yok) ve satır sayısı testleri FAIL (7 satır var, 25 bekleniyor).

- [ ] **Step 3: Veriyi genişlet**

`WHOPercentiles.swift` içindeki altı tabloya (`weightFemale`, `weightMale`, `heightFemale`, `heightMale`, `headFemale`, `headMale`) 7–24 ay satırları eklenir. Format değişmiyor: `(month, p3, p15, p50, p85, p97)`.

Veri kaynağı: WHO Child Growth Standards, "Weight-for-age", "Length/height-for-age", "Head circumference-for-age" — 0–2 yıl, cinsiyete göre percentile tabloları (https://www.who.int/tools/child-growth-standards/standards). Kilo kg, boy ve baş çevresi cm; mevcut satırlarla aynı ondalık hassasiyeti (kilo 1 ondalık, boy/baş 1 ondalık) kullanılır.

Dosya başındaki doc comment'te "0-6 ay" ifadesi "0-24 ay" olarak güncellenir.

- [ ] **Step 4: `percentileBand`'ı düzelt**

`WHOPercentiles.swift`, mevcut `percentileBand` gövdesi bununla değiştirilir:

```swift
    /// Tablonun kapsadığı en büyük yaş (ay).
    static let maxAgeMonths = 24

    /// Verilen ay ve değer için yaklaşık persentil bandını döner.
    /// Tablo dışı yaşta `nil` döner — çağıran taraf "veri yok" gösterir.
    /// (Önceden ay clamp ediliyordu; 14 aylık bebek 6. ay eğrisiyle
    /// karşılaştırılıp sessizce yanlış sonuç üretiyordu.)
    static func percentileBand(
        metric: Metric, sex: Sex, ageMonths: Int, value: Double
    ) -> String? {
        let rows = data(for: metric, sex: sex)
        guard let row = rows.first(where: { $0.month == ageMonths }) else { return nil }

        if value < row.p3 { return "< 3. persentil" }
        if value < row.p15 { return "3–15. persentil" }
        if value <= row.p85 { return "15–85. persentil (normal aralık)" }
        if value <= row.p97 { return "85–97. persentil" }
        return "> 97. persentil"
    }
```

`< 3.persentil` ve `> 97.persentil` metinlerindeki eksik boşluk da düzeltildi (nokta sonrası boşluk).

- [ ] **Step 5: `GrowthView`'ı uyarla**

`Features/Growth/GrowthView.swift:151` — sabit `chartXScale(domain: 0...6)` bebeğin yaşına göre dinamik hâle gelir:

```swift
        .chartXScale(domain: 0...Double(chartMaxMonth))
```

Aynı dosyaya yardımcı property eklenir (`ageMonths(at:)` fonksiyonunun hemen üstüne):

```swift
    /// Grafiğin sağ sınırı: bebeğin yaşından bir miktar ileriyi gösterir ama
    /// tablo sınırını aşmaz. Sabit 0...24 kullanmak 2 aylık bebekte grafiği
    /// okunamaz hâle getirirdi.
    private var chartMaxMonth: Int {
        min(WHOPercentiles.maxAgeMonths, max(6, baby.ageInMonths + 2))
    }
```

`GrowthView.swift:184` — `percentileBand` artık optional döndüğü için `latestValueRow` içindeki çağrı:

```swift
        let band = WHOPercentiles.percentileBand(
            metric: selectedMetric, sex: sex, ageMonths: months, value: value
        ) ?? "Bu yaş için persentil verisi yok"
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/WHOPercentileTests" -quiet
```

Beklenen: tüm testler PASS. Monotonluk testi FAIL ederse veri girişinde yazım hatası vardır — hangi ay/metrik olduğu mesajda yazar.

- [ ] **Step 7: Commit**

```bash
git add "Baby Care/Core/Models/WHOPercentiles.swift" \
        "Baby Care/Features/Growth/GrowthView.swift" \
        "Baby CareTests/WHOPercentileTests.swift"
git commit -m "fix: WHO persentil tabloları 24 aya genişletildi, clamp hatası giderildi

percentileBand ayı min(rows.count-1) ile kırpıyordu; 14 aylık bebeğin
kilosu 6. ay eğrisiyle karşılaştırılıp hata vermeden yanlış persentil
basıyordu. Artık tablo dışı yaşta nil dönüyor.

Büyüme grafiğinin x ekseni de bebeğin yaşına göre dinamik.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 3: Aşı takvimi 0–24 ay (H-2, H-3)

Resmi 2025 takviminde KPA şeması 2+1 (2., 4., 12. ay) — uygulamadaki `kpa_6m` fazla. 9. ay KKK ek dozu ise eksik.

**Files:**
- Modify: `Baby Care/Core/Models/VaccineCatalog.swift`
- Modify: `Baby Care/Core/Services/VaccinationScheduler.swift:18`
- Test: `Baby CareTests/VaccineCatalogTests.swift`

**Interfaces:**
- Consumes: `VaccineDefinition` (mevcut struct, bir alan eklenir)
- Produces: `VaccineCatalog.schedule: [VaccineDefinition]` (eski adı `firstSixMonths`), `VaccineCatalog.definition(forID:)` (mevcut, değişmez), `VaccineDefinition.isRetired: Bool` (yeni alan)

- [ ] **Step 1: Write the failing test**

`Baby CareTests/VaccineCatalogTests.swift`:

```swift
import Testing
import Foundation
@testable import Baby_Care

struct VaccineCatalogTests {

    @Test func kpaIsTwoPlusOneSchedule() {
        // T.C. Sağlık Bakanlığı 2025 takvimi: KPA 2., 4. ay ve 12. ay rapel.
        // 6. ayda KPA yok — eski katalogda hatalı bir kpa_6m tanımı vardı.
        let kpaMonths = VaccineCatalog.schedule
            .filter { $0.shortName.contains("KPA") && !$0.isRetired }
            .map(\.scheduledAgeMonths)
            .sorted()
        #expect(kpaMonths == [2, 4, 12])
    }

    @Test func retiredKpaSixMonthDefinitionStillResolves() {
        // Mevcut kullanıcılarda kpa_6m kaydı olabilir; UI ham id göstermesin.
        let def = VaccineCatalog.definition(forID: "kpa_6m")
        #expect(def != nil)
        #expect(def?.isRetired == true)
    }

    @Test func retiredDefinitionsAreExcludedFromScheduling() {
        #expect(VaccineCatalog.scheduled.contains { $0.isRetired } == false)
    }

    @Test func ninthMonthMeaslesExtraDoseExists() {
        let ninth = VaccineCatalog.scheduled.filter { $0.scheduledAgeMonths == 9 }
        #expect(ninth.count == 1)
        #expect(ninth.first?.shortName.contains("KKK") == true)
    }

    @Test func twelfthMonthHasThreeVaccines() {
        let ids = Set(VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 12 }.map(\.id))
        #expect(ids == ["kpa_12m", "varicella_12m", "mmr_12m"])
    }

    @Test func eighteenthMonthHasThreeVaccines() {
        let ids = Set(VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 18 }.map(\.id))
        #expect(ids == ["hexa_18m", "opa_18m", "hepa_18m"])
    }

    @Test func twentyFourthMonthHasHepatitisASecondDose() {
        let ids = VaccineCatalog.scheduled
            .filter { $0.scheduledAgeMonths == 24 }.map(\.id)
        #expect(ids == ["hepa_24m"])
    }

    @Test func catalogStopsAtTwentyFourMonths() {
        // 48. ay ve 13 yaş aşıları kapsam dışı.
        #expect(VaccineCatalog.scheduled.allSatisfy { $0.scheduledAgeMonths <= 24 })
    }

    @Test func everyDefinitionHasNonEmptyContent() {
        for def in VaccineCatalog.schedule {
            #expect(!def.id.isEmpty)
            #expect(!def.shortName.isEmpty)
            #expect(!def.fullName.isEmpty)
            #expect(!def.description.isEmpty)
            #expect(!def.route.isEmpty)
        }
    }

    @Test func identifiersAreUnique() {
        let ids = VaccineCatalog.schedule.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/VaccineCatalogTests" -quiet
```

Beklenen: derleme hatası — `schedule`, `scheduled` ve `isRetired` yok.

- [ ] **Step 3: `VaccineDefinition`'a `isRetired` ekle ve katalogu genişlet**

`VaccineCatalog.swift`. Struct'a alan eklenir:

```swift
struct VaccineDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let shortName: String
    let fullName: String
    let scheduledAgeMonths: Int
    let scheduledAgeDays: Int
    let description: String
    let route: String
    let isOptional: Bool
    /// Takvimden çıkarılmış tanım. Yeni kayıt üretilmez, ama mevcut
    /// kullanıcı kayıtlarının adı çözümlenebilsin diye katalogda kalır.
    var isRetired: Bool = false
}
```

`static let firstSixMonths` → `static let schedule` olarak yeniden adlandırılır. Mevcut yedi tanım (`hepb_birth`, `bcg_2m`, `hexa_2m`, `kpa_2m`, `hexa_4m`, `kpa_4m`, `hexa_6m`, `opa_6m`) korunur. `kpa_6m` **silinmez**, `isRetired: true` işaretlenir ve açıklaması güncellenir:

```swift
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
        ),
```

Eklenen tanımlar (2025 Ulusal Çocukluk Dönemi Aşılama Takvimi):

| id | shortName | ay | route |
|---|---|---|---|
| `mmr_9m` | KKK Ek Doz | 9 | Cilt altı |
| `mmr_12m` | KKK 1. doz | 12 | Cilt altı |
| `varicella_12m` | Suçiçeği 1. doz | 12 | Cilt altı |
| `kpa_12m` | KPA Pekiştirme | 12 | Kas içi |
| `hexa_18m` | Altılı Karma Pekiştirme | 18 | Kas içi (uyluk) |
| `opa_18m` | OPA 2. doz | 18 | Ağızdan (oral) |
| `hepa_18m` | Hepatit A 1. doz | 18 | Kas içi |
| `hepa_24m` | Hepatit A 2. doz | 24 | Kas içi |

Her tanımın `fullName`, `description` ve `route` alanları mevcut kayıtlarla aynı üslupta doldurulur; `isOptional: false`.

Dosya başındaki doc comment "0-6 ay" → "0-24 ay" olarak güncellenir, kaynak satırına takvim PDF'i eklenir.

Ayrıca planlamada kullanılacak filtrelenmiş liste:

```swift
    /// Yeni bebek için takvim üretirken kullanılan liste — emekli tanımlar hariç.
    static var scheduled: [VaccineDefinition] {
        schedule.filter { !$0.isRetired }
    }
```

- [ ] **Step 4: `VaccinationScheduler`'ı güncelle**

`Core/Services/VaccinationScheduler.swift:18`:

```swift
        for vaccine in VaccineCatalog.scheduled {
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/VaccineCatalogTests" -quiet
```

Beklenen: 10 test PASS.

- [ ] **Step 6: Commit**

```bash
git add "Baby Care/Core/Models/VaccineCatalog.swift" \
        "Baby Care/Core/Services/VaccinationScheduler.swift" \
        "Baby CareTests/VaccineCatalogTests.swift"
git commit -m "fix: aşı takvimi 24 aya genişletildi, KPA şeması düzeltildi

Resmi 2025 takviminde KPA 2+1 (2., 4., 12. ay). Uygulamadaki kpa_6m
fazlaydı — emekli olarak işaretlendi, yeni kayıt üretilmiyor. 9. ay KKK
ek dozu eksikti, eklendi. 12/18/24. ay aşıları takvime girdi.

Kaynak: asi.saglik.gov.tr 2025 aşı takvimi PDF.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 4: kpa_6m temizlik migration'ı

Mevcut kullanıcılarda `kpa_6m` için planlanmış kayıt var. Yapılmamış olanlar silinir; yapılmış olanlar korunur (kullanıcı gerçekten yaptırmış olabilir, verisini silmeyiz).

**Files:**
- Create: `Baby Care/Core/Services/VaccinationMigration.swift`
- Modify: `Baby Care/App/RootView.swift:18-22` (task bloğu)
- Test: `Baby CareTests/VaccinationMigrationTests.swift`

**Interfaces:**
- Consumes: `VaccinationRecord`, `NotificationService.cancelReminders(for:)`
- Produces: `VaccinationMigration.removeRetiredPendingRecords(in context: ModelContext) async -> Int` (silinen kayıt sayısını döner)

- [ ] **Step 1: Write the failing test**

`Baby CareTests/VaccinationMigrationTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Baby_Care

@MainActor
struct VaccinationMigrationTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Baby.self, VaccinationRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test func removesPendingRetiredRecord() async throws {
        let context = try makeContext()
        let babyID = UUID()
        context.insert(VaccinationRecord(
            babyID: babyID, vaccineDefinitionID: "kpa_6m", scheduledDate: .now
        ))
        try context.save()

        let removed = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(removed == 1)
        let remaining = try context.fetch(FetchDescriptor<VaccinationRecord>())
        #expect(remaining.isEmpty)
    }

    @Test func keepsCompletedRetiredRecord() async throws {
        let context = try makeContext()
        let record = VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "kpa_6m", scheduledDate: .now
        )
        record.completedDate = .now
        context.insert(record)
        try context.save()

        let removed = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(removed == 0)
        let remaining = try context.fetch(FetchDescriptor<VaccinationRecord>())
        #expect(remaining.count == 1)
    }

    @Test func leavesActiveRecordsUntouched() async throws {
        let context = try makeContext()
        context.insert(VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "hexa_6m", scheduledDate: .now
        ))
        try context.save()

        let removed = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(removed == 0)
        let remaining = try context.fetch(FetchDescriptor<VaccinationRecord>())
        #expect(remaining.count == 1)
    }

    @Test func isIdempotent() async throws {
        let context = try makeContext()
        context.insert(VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "kpa_6m", scheduledDate: .now
        ))
        try context.save()

        let first = await VaccinationMigration.removeRetiredPendingRecords(in: context)
        let second = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(first == 1)
        #expect(second == 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/VaccinationMigrationTests" -quiet
```

Beklenen: `cannot find 'VaccinationMigration' in scope`.

- [ ] **Step 3: Write minimal implementation**

`Baby Care/Core/Services/VaccinationMigration.swift`:

```swift
import Foundation
import SwiftData

/// Takvimden çıkarılan aşı tanımları için tek seferlik veri temizliği.
///
/// 2025 ulusal takviminde KPA şeması 2+1 olduğu için `kpa_6m` emekliye
/// ayrıldı. Mevcut kullanıcılarda o tanıma bağlı planlanmış kayıtlar
/// kalabilir; yapılmamış olanlar silinir. Tamamlanmış kayıtlara
/// dokunulmaz — kullanıcı gerçekten yaptırmış olabilir.
@MainActor
enum VaccinationMigration {

    @discardableResult
    static func removeRetiredPendingRecords(in context: ModelContext) async -> Int {
        let retiredIDs = Set(VaccineCatalog.schedule.filter(\.isRetired).map(\.id))
        guard !retiredIDs.isEmpty else { return 0 }

        let all = (try? context.fetch(FetchDescriptor<VaccinationRecord>())) ?? []
        let targets = all.filter {
            retiredIDs.contains($0.vaccineDefinitionID) && $0.completedDate == nil
        }
        guard !targets.isEmpty else { return 0 }

        for record in targets {
            await NotificationService.cancelReminders(for: record)
            context.delete(record)
        }
        try? context.save()
        return targets.count
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Aynı komut. Beklenen: 4 test PASS.

- [ ] **Step 5: Uygulama açılışına bağla**

`App/RootView.swift`, mevcut `.task` bloğuna eklenir:

```swift
        .task {
            // Takvimden çıkarılmış aşı kayıtlarını temizle (idempotent)
            await VaccinationMigration.removeRetiredPendingRecords(in: modelContext)
            // Pazar 19:00 haftalık özet + Pazar 10:00 büyüme ölçüm hatırlatması
            await NotificationService.scheduleWeeklySummary()
            await NotificationService.scheduleWeeklyGrowthReminder()
        }
```

Aynı dosyanın başına `modelContext` erişimi eklenir (şu an yok):

```swift
    @Environment(\.modelContext) private var modelContext
```

- [ ] **Step 6: Run full unit suite**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests" -quiet
```

Beklenen: hepsi PASS.

- [ ] **Step 7: Commit**

```bash
git add "Baby Care/Core/Services/VaccinationMigration.swift" \
        "Baby Care/App/RootView.swift" \
        "Baby CareTests/VaccinationMigrationTests.swift"
git commit -m "fix: emekli aşı tanımlarının bekleyen kayıtlarını temizle

kpa_6m takvimden çıktı. Yapılmamış kayıtlar açılışta siliniyor,
tamamlanmış olanlar korunuyor. İşlem idempotent.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 5: Yaşa duyarlı beslenme hesabı (H-4)

`FeedingCalculator` 150–180 ml/kg sabitini her yaşa uyguluyor. Ek gıda başlayınca süt ihtiyacı düşer; hesap fazla çıkıyor.

**Files:**
- Modify: `Baby Care/Core/Services/FeedingCalculator.swift`
- Modify: `Baby Care/Features/Profile/FeedingCalculatorView.swift` (yeni alanların gösterimi)
- Test: `Baby CareTests/FeedingCalculatorTests.swift`

**Interfaces:**
- Consumes: `BabyStage.forAgeMonths(_:)` (Task 1)
- Produces: `FeedingCalculator.calculate(ageDays:weightKg:) -> Result` (imza aynı), `Result.solidFoodKcal: Int?` ve `Result.stage: BabyStage` (yeni alanlar), `Result.milkNote: String`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/FeedingCalculatorTests.swift`:

```swift
import Testing
@testable import Baby_Care

struct FeedingCalculatorTests {

    @Test func firstWeekUsesAscendingPerKgValues() {
        let day1 = FeedingCalculator.calculate(ageDays: 0, weightKg: 3.2)
        #expect(day1.mlPerKgMin == 60)
        let day3 = FeedingCalculator.calculate(ageDays: 2, weightKg: 3.2)
        #expect(day3.mlPerKgMin == 100)
    }

    @Test func infantUnderSixMonthsUsesFullMilkRange() {
        let threeMonths = FeedingCalculator.calculate(ageDays: 90, weightKg: 6.0)
        #expect(threeMonths.mlPerKgMin == 150)
        #expect(threeMonths.mlPerKgMax == 180)
        #expect(threeMonths.stage == .newborn)
        #expect(threeMonths.solidFoodKcal == nil)
    }

    @Test func complementaryStageReducesMilkTarget() {
        // 8 aylık: süt ana besin olmayı sürdürür ama ek gıda enerjinin bir
        // kısmını karşılar; ml/kg hedefi düşer.
        let eightMonths = FeedingCalculator.calculate(ageDays: 240, weightKg: 8.5)
        #expect(eightMonths.stage == .complementary)
        #expect(eightMonths.mlPerKgMax < 150)
        #expect(eightMonths.dailyMaxML < FeedingCalculator
            .calculate(ageDays: 90, weightKg: 8.5).dailyMaxML)
    }

    @Test func complementaryStageReportsSolidFoodEnergy() {
        // TÜBER 2022: 6-8 ay ~200 kcal, 9-11 ay ~300 kcal, 12-24 ay ~550 kcal
        #expect(FeedingCalculator.calculate(ageDays: 210, weightKg: 8.0).solidFoodKcal == 200)
        #expect(FeedingCalculator.calculate(ageDays: 300, weightKg: 9.0).solidFoodKcal == 300)
        #expect(FeedingCalculator.calculate(ageDays: 450, weightKg: 10.5).solidFoodKcal == 550)
    }

    @Test func toddlerStageIsDetected() {
        let eighteenMonths = FeedingCalculator.calculate(ageDays: 548, weightKg: 11.0)
        #expect(eighteenMonths.stage == .toddler)
        #expect(eighteenMonths.solidFoodKcal == 550)
    }

    @Test func milkNoteIsNeverEmpty() {
        for days in [0, 30, 90, 200, 300, 400, 700] {
            let result = FeedingCalculator.calculate(ageDays: days, weightKg: 7.0)
            #expect(!result.milkNote.isEmpty)
        }
    }

    @Test func typicalFeedingsDecreaseWithAge() {
        let newborn = FeedingCalculator.calculate(ageDays: 10, weightKg: 3.5)
        let sixMonths = FeedingCalculator.calculate(ageDays: 190, weightKg: 7.8)
        #expect(newborn.typicalFeedingsPerDay > sixMonths.typicalFeedingsPerDay)
    }

    @Test func weightIsClampedToMinimum() {
        let result = FeedingCalculator.calculate(ageDays: 30, weightKg: 0.1)
        #expect(result.weightKg == 0.5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/FeedingCalculatorTests" -quiet
```

Beklenen: `Result` üzerinde `stage`, `solidFoodKcal`, `milkNote` yok — derleme hatası.

- [ ] **Step 3: Write implementation**

`FeedingCalculator.swift`. `Result` struct'ına üç alan eklenir:

```swift
        /// Bebeğin bakım dönemi — hesabın hangi kurala göre yapıldığını gösterir.
        let stage: BabyStage
        /// Ek gıdadan gelmesi beklenen günlük enerji (kcal). 6 ay altında nil.
        let solidFoodKcal: Int?
        /// Süt hedefinin nasıl yorumlanacağına dair kısa not.
        let milkNote: String
```

`calculate` gövdesindeki yaş dalı genişletilir:

```swift
    static func calculate(ageDays: Int, weightKg: Double) -> Result {
        let kg = max(0.5, weightKg)
        let ageMonths = ageDays / 30
        let stage = BabyStage.forAgeMonths(ageMonths)

        let (minPerKg, maxPerKg): (Double, Double)
        let solidKcal: Int?
        let note: String

        if ageDays < 7 {
            let single = firstWeekMlPerKg(day: max(1, ageDays + 1))
            minPerKg = single
            maxPerKg = single
            solidKcal = nil
            note = "İlk günlerde mide kapasitesi hızla artar. Bebek doyduğu kadar beslenmelidir."
        } else if stage == .newborn {
            minPerKg = 150
            maxPerKg = 180
            solidKcal = nil
            note = "Bu dönemde tek besin anne sütü veya mamadır; ek gıda 6. ayda başlar."
        } else if stage == .complementary {
            // Ek gıda enerjinin bir kısmını karşıladığı için süt hedefi düşer.
            minPerKg = 100
            maxPerKg = 130
            solidKcal = ageMonths < 9 ? 200 : 300
            note = "Anne sütü ana besin olmayı sürdürür; ek gıda yanında verilir, yerine değil."
        } else {
            minPerKg = 70
            maxPerKg = 100
            solidKcal = 550
            note = "Bu yaşta beslenmenin merkezi aile sofrasıdır. Anne sütü 2 yaşına kadar sürebilir."
        }

        let dailyMin = minPerKg * kg
        let dailyMax = maxPerKg * kg
        let dailyAvg = (dailyMin + dailyMax) / 2

        let typicalFeedings: Int
        switch ageDays {
        case 0..<30:   typicalFeedings = 9
        case 30..<90:  typicalFeedings = 7
        case 90..<180: typicalFeedings = 5
        case 180..<365: typicalFeedings = 4
        default:       typicalFeedings = 3
        }

        let kcalPer100ml: Double = 67
        let caloriesMin = Int((dailyMin / 100.0) * kcalPer100ml)
        let caloriesMax = Int((dailyMax / 100.0) * kcalPer100ml)

        return Result(
            weightKg: kg,
            ageDays: ageDays,
            mlPerKgMin: minPerKg,
            mlPerKgMax: maxPerKg,
            dailyMinML: Int(dailyMin.rounded()),
            dailyMaxML: Int(dailyMax.rounded()),
            dailyAverageML: Int(dailyAvg.rounded()),
            typicalFeedingsPerDay: typicalFeedings,
            dailyCaloriesMin: caloriesMin,
            dailyCaloriesMax: caloriesMax,
            stage: stage,
            solidFoodKcal: solidKcal,
            milkNote: note
        )
    }
```

Dosya başındaki doc comment'te "1 hafta – 6 ay: 150–180 ml/kg/gün" satırının altına 6–12 ay ve 12–24 ay aralıkları eklenir; kaynak olarak TÜBER 2022 belirtilir.

- [ ] **Step 4: `FeedingCalculatorView`'a yeni alanları ekle**

`Features/Profile/FeedingCalculatorView.swift` içinde sonuç bölümüne, mevcut kalori satırının altına eklenir:

```swift
                if let kcal = result.solidFoodKcal {
                    LabeledContent("Ek gıdadan hedef enerji", value: "\(kcal) kcal/gün")
                }
                Text(result.milkNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/FeedingCalculatorTests" -quiet
```

Beklenen: 8 test PASS.

- [ ] **Step 6: Commit**

```bash
git add "Baby Care/Core/Services/FeedingCalculator.swift" \
        "Baby Care/Features/Profile/FeedingCalculatorView.swift" \
        "Baby CareTests/FeedingCalculatorTests.swift"
git commit -m "fix: beslenme hesabı yaşa duyarlı hâle getirildi

150-180 ml/kg her yaşa uygulanıyordu. Ek gıda başlayınca süt ihtiyacı
düşer; 6-12 ay ve 12-24 ay için ayrı aralıklar ve ek gıdadan beklenen
günlük enerji eklendi (TÜBER 2022).

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 6: Gelişim rehberi 6–24 ay aşamaları

Şu an `stage_26_plus` "Uygulamanın hedef kapsamı dışında" diyor ve 6 ay üstü kullanıcı boş ekran görüyor.

**Files:**
- Modify: `Baby Care/Core/Models/GuideCatalog.swift`
- Test: `Baby CareTests/GuideCatalogTests.swift`

**Interfaces:**
- Consumes: `GuideStage` struct (mevcut, değişmiyor)
- Produces: `GuideCatalog.stages` (5 yeni aşama, `stage_26_plus` kaldırılır), `GuideCatalog.stage(forAgeWeeks:)` (mevcut imza korunur)

- [ ] **Step 1: Write the failing test**

`Baby CareTests/GuideCatalogTests.swift`:

```swift
import Testing
@testable import Baby_Care

struct GuideCatalogTests {

    @Test func stagesCoverBirthToTwentyFourMonthsWithoutGaps() {
        let stages = GuideCatalog.stages
        #expect(stages.first?.minWeeks == 0)
        for (prev, next) in zip(stages, stages.dropFirst()) {
            #expect(next.minWeeks == prev.maxWeeks,
                    "\(prev.id) → \(next.id) arasında boşluk veya çakışma var")
        }
        // Son aşama en az 104 haftayı (24 ay) kapsamalı
        #expect((stages.last?.maxWeeks ?? 0) >= 104)
    }

    @Test func outOfScopePlaceholderIsGone() {
        let joined = GuideCatalog.stages
            .flatMap { [$0.summary] + $0.grossMotor }
            .joined(separator: " ")
        #expect(!joined.contains("kapsamı dışında"))
    }

    @Test func everyStageHasContentInAllCategories() {
        for stage in GuideCatalog.stages {
            #expect(!stage.title.isEmpty, "\(stage.id): başlık boş")
            #expect(!stage.summary.isEmpty, "\(stage.id): özet boş")
            #expect(!stage.grossMotor.isEmpty, "\(stage.id): kaba motor boş")
            #expect(!stage.fineMotor.isEmpty, "\(stage.id): ince motor boş")
            #expect(!stage.language.isEmpty, "\(stage.id): dil boş")
            #expect(!stage.socialEmotional.isEmpty, "\(stage.id): sosyal-duygusal boş")
            #expect(!stage.feedingTips.isEmpty, "\(stage.id): beslenme boş")
            #expect(!stage.sleepTips.isEmpty, "\(stage.id): uyku boş")
            #expect(!stage.warningSigns.isEmpty, "\(stage.id): uyarı işaretleri boş")
        }
    }

    @Test func identifiersAreUnique() {
        let ids = GuideCatalog.stages.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func lookupResolvesSolidFoodAges() {
        // 30 hafta ≈ 7 ay, 60 hafta ≈ 14 ay, 100 hafta ≈ 23 ay
        #expect(GuideCatalog.stage(forAgeWeeks: 30).id == "stage_6_8m")
        #expect(GuideCatalog.stage(forAgeWeeks: 60).id == "stage_12_15m")
        #expect(GuideCatalog.stage(forAgeWeeks: 100).id == "stage_18_24m")
    }

    @Test func lookupClampsBeyondTwentyFourMonths() {
        // 3 yaşındaki bir çocukta son aşama dönmeli, çökmemeli
        #expect(GuideCatalog.stage(forAgeWeeks: 160).id == "stage_18_24m")
    }

    @Test func solidFoodStagesMentionFeedingProgression() {
        let sixToEight = GuideCatalog.stages.first { $0.id == "stage_6_8m" }!
        let joined = sixToEight.feedingTips.joined(separator: " ")
        #expect(joined.contains("demir") || joined.contains("Demir"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/GuideCatalogTests" -quiet
```

Beklenen: `stage_6_8m` bulunamadığı için lookup testleri FAIL; "kapsamı dışında" testi FAIL.

- [ ] **Step 3: Aşamaları yaz**

`GuideCatalog.swift`. `stage_26_plus` tanımı **silinir**, yerine beş aşama gelir. `stage_22_26w` aşamasının `maxWeeks` değeri 26 kalır; yeni aşamalar oradan devam eder:

| id | minWeeks | maxWeeks | title |
|---|---|---|---|
| `stage_6_8m` | 26 | 35 | 6–8 ay |
| `stage_9_11m` | 35 | 52 | 9–11 ay |
| `stage_12_15m` | 52 | 65 | 12–15 ay |
| `stage_15_18m` | 65 | 78 | 15–18 ay |
| `stage_18_24m` | 78 | `Int.max` | 18–24 ay |

Her aşamada dokuz alan da doldurulur. `feedingTips` içeriği spec bölüm 6.5'teki doğrulanmış tablodan gelir — kıvam, öğün sayısı, porsiyon, ek gıdadan enerji, demir vurgusu ve yaş bariyerleri. Örnek olarak `stage_6_8m`:

```swift
        GuideStage(
            id: "stage_6_8m",
            minWeeks: 26, maxWeeks: 35,
            title: "6–8 ay (Ek gıdaya geçiş)",
            summary: "Tamamlayıcı beslenme başlar. Anne sütü ana besin olmayı sürdürür.",
            grossMotor: [
                "Desteksiz oturur.",
                "Emekleme denemeleri başlar.",
                "Yüzükoyunken kollarıyla itip geriye kayabilir."
            ],
            fineMotor: [
                "Nesneleri bir elden diğerine geçirir.",
                "Parmak besinleri avuçlayarak tutar.",
                "Kaşığa uzanır."
            ],
            language: [
                "Tekrarlı heceler artar ('ba-ba', 'ma-ma').",
                "Adına tutarlı biçimde dönüp bakar.",
                "Ses tonundan duyguyu ayırt eder."
            ],
            socialEmotional: [
                "Yabancı kaygısı başlayabilir.",
                "Aynadaki görüntüsüne tepki verir.",
                "Basit 'ce-ee' oyunlarından hoşlanır."
            ],
            feedingTips: [
                "Ek gıda 6. ay dolunca (180. gün) başlar; 2–3 ana öğün, iştaha göre 1–2 ara öğün.",
                "2–3 tatlı kaşığıyla başlanır, kademeli olarak öğün başına ~125 ml'ye çıkılır.",
                "Demir açısından zengin besinler önceliklidir: kırmızı et, tavuk, balık, yumurta sarısı.",
                "Bitkisel demirin emilimi için C vitamini içeren sebze veya meyveyle birlikte verin.",
                "Bal 1 yaşından önce verilmez (infantil botulizm riski).",
                "Yemeğe tuz ve şeker eklenmez.",
                "8. ay dolaylarında yumuşak parmak besinlere geçilebilir."
            ],
            sleepTips: [
                "Toplam 12–15 saat; genelde 2 gündüz şekerlemesi.",
                "Gece uyanmaları diş çıkarma veya ayrılık kaygısıyla artabilir."
            ],
            warningSigns: [
                "Desteksiz oturamama",
                "Katı gıdayı ağzında tutamama veya sürekli püskürtme",
                "Göz teması kurmama, sesle tepki vermeme",
                "Kilo alımının durması"
            ]
        ),
```

Kalan dört aşama aynı yapıda yazılır. `stage_9_11m` beslenme ipuçlarında 3–4 ana öğün, ince doğranmış kıvam ve ~300 kcal; `stage_12_15m` aile yemeği, inek sütünün artık ana içecek olabileceği, ~180 ml/öğün ve ~550 kcal; `stage_15_18m` ve `stage_18_24m` seçici yeme dönemi, kendi kaşığıyla yeme ve 2 yaşına kadar ilave şekerden kaçınma.

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/GuideCatalogTests" -quiet
```

Beklenen: 7 test PASS.

- [ ] **Step 5: Commit**

```bash
git add "Baby Care/Core/Models/GuideCatalog.swift" \
        "Baby CareTests/GuideCatalogTests.swift"
git commit -m "feat: gelişim rehberi 24 aya genişletildi

6-8, 9-11, 12-15, 15-18 ve 18-24 ay aşamaları eklendi.
'Kapsam dışında' placeholder aşaması kaldırıldı.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 7: Alerjen enum'u ve kataloğu

**Files:**
- Create: `Baby Care/Core/Models/Allergen.swift`
- Test: `Baby CareTests/AllergenCatalogTests.swift`

**Interfaces:**
- Consumes: yok
- Produces: `enum Allergen: String, CaseIterable, Codable, Sendable` (9 case: `milk, egg, peanut, treeNut, wheat, soy, sesame, fish, shellfish`), `Allergen.localizedTitle`, `Allergen.icon`, `struct AllergenInfo`, `AllergenCatalog.info(for: Allergen) -> AllergenInfo`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/AllergenCatalogTests.swift`:

```swift
import Testing
@testable import Baby_Care

struct AllergenCatalogTests {

    @Test func nineMajorAllergensAreDefined() {
        #expect(Allergen.allCases.count == 9)
    }

    @Test func everyAllergenHasCompleteInfo() {
        for allergen in Allergen.allCases {
            let info = AllergenCatalog.info(for: allergen)
            #expect(!allergen.localizedTitle.isEmpty, "\(allergen): başlık boş")
            #expect(!info.introductionGuidance.isEmpty, "\(allergen): tanıtım rehberi boş")
            #expect(!info.safeServingForm.isEmpty, "\(allergen): sunum biçimi boş")
            #expect(!info.sourceURL.isEmpty, "\(allergen): kaynak linki boş")
            #expect(info.sourceURL.hasPrefix("https://"), "\(allergen): kaynak https değil")
        }
    }

    @Test func minimumIntroductionAgeIsNeverBelowFourMonths() {
        // Hiçbir kılavuz 4 tamamlanmış aydan önce tanıtım önermez.
        for allergen in Allergen.allCases {
            #expect(AllergenCatalog.info(for: allergen).minAgeMonths >= 4)
        }
    }

    @Test func peanutAndEggAreMarkedProtective() {
        // LEAP ve EAACI: erken tanıtımın koruyucu etkisi bu ikisinde güçlü.
        #expect(AllergenCatalog.info(for: .peanut).hasStrongEvidence == true)
        #expect(AllergenCatalog.info(for: .egg).hasStrongEvidence == true)
        #expect(AllergenCatalog.info(for: .shellfish).hasStrongEvidence == false)
    }

    @Test func chokingHazardsAreFlaggedForNutsAndSeeds() {
        // Bütün fındık ve koyu ezme boğulma tehlikesi — sunum notu bunu söylemeli.
        #expect(AllergenCatalog.info(for: .peanut).safeServingForm.contains("incelt"))
        #expect(AllergenCatalog.info(for: .treeNut).safeServingForm.contains("incelt"))
        #expect(AllergenCatalog.info(for: .sesame).safeServingForm.contains("incelt"))
    }

    @Test func rawValuesAreStableForPersistence() {
        // SwiftData'da rawValue saklanıyor; değişirse mevcut kayıtlar kopar.
        #expect(Allergen.milk.rawValue == "milk")
        #expect(Allergen.egg.rawValue == "egg")
        #expect(Allergen.peanut.rawValue == "peanut")
        #expect(Allergen.treeNut.rawValue == "treeNut")
        #expect(Allergen.wheat.rawValue == "wheat")
        #expect(Allergen.soy.rawValue == "soy")
        #expect(Allergen.sesame.rawValue == "sesame")
        #expect(Allergen.fish.rawValue == "fish")
        #expect(Allergen.shellfish.rawValue == "shellfish")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/AllergenCatalogTests" -quiet
```

Beklenen: `cannot find 'Allergen' in scope`.

- [ ] **Step 3: Write implementation**

`Baby Care/Core/Models/Allergen.swift`:

```swift
import Foundation

/// FDA "Big 9" major besin alerjenleri.
///
/// Tanıtım yaklaşımı güncel uluslararası konsensüse dayanır (ESPGHAN,
/// AAP 2023, EAACI 2021, NIAID): alerjenler geciktirilmez, tamamlayıcı
/// beslenmeyle birlikte yaklaşık 6. ayda ve hiçbir zaman 4 tamamlanmış
/// aydan önce olmamak üzere tanıtılır. Tolere edilen alerjen diyette
/// düzenli tutulur.
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
                introductionGuidance: "Yaklaşık 6. ayda, 4 aydan önce olmamak üzere tanıtın. Tolere edilirse haftada birkaç kez vermeyi sürdürün.",
                safeServingForm: "İyi pişmiş (haşlanmış veya çırpılmış) yumurtayı ezip küçük miktarla başlayın; gerekirse anne sütü veya püreyle inceltin. Çiğ ya da az pişmiş yumurta vermeyin.",
                hasStrongEvidence: true,
                sourceURL: "https://eaaci.org/guidelines-position-papers/eaaci-guideline-preventing-the-development-of-food-allergy-in-infants-and-young-children-2020-update/"
            )
        case .peanut:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda tanıtın. Bebeğinizde ağır egzama veya yumurta alerjisi varsa, tanıtımdan önce çocuk hekimine danışın.",
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
                introductionGuidance: "Yaklaşık 6. ayda, ilk yıl içinde tanıtın.",
                safeServingForm: "Tahini su, yoğurt veya tolere edilmiş bir püreyle inceltin. Koyu tahin ya da bütün susam tanesi vermeyin.",
                hasStrongEvidence: false,
                sourceURL: "https://www.fda.gov/food/buy-store-serve-safe-food/food-allergies-what-you-need-know"
            )
        case .fish:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Yaklaşık 6. ayda tanıtın. Bir balık türünü tolere etmek diğerlerini garanti etmez.",
                safeServingForm: "Tam pişmiş, bütün kılçıkları ayıklanmış, ezilmiş veya ince parçalanmış balık.",
                hasStrongEvidence: false,
                sourceURL: "https://www.nhs.uk/baby/weaning-and-feeding/food-allergies-in-babies-and-young-children/"
            )
        case .treeNut:
            return AllergenInfo(
                minAgeMonths: 6,
                introductionGuidance: "Badem, ceviz, fındık, kaju gibi yemişler ayrı ayrı tanıtılabilir. İlk yıl içinde geciktirmeyin.",
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/AllergenCatalogTests" -quiet
```

Beklenen: 6 test PASS.

- [ ] **Step 5: Commit**

```bash
git add "Baby Care/Core/Models/Allergen.swift" \
        "Baby CareTests/AllergenCatalogTests.swift"
git commit -m "feat: 9 major alerjen ve tanıtım rehberi kataloğu

ESPGHAN/AAP 2023/EAACI/NIAID çizgisi: alerjenler geciktirilmez,
~6. ayda tanıtılır. Her alerjende boğulma riski yaratmayan sunum
biçimi ve resmi kaynak linki var.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 8: Besin kütüphanesi

**Files:**
- Create: `Baby Care/Core/Models/FoodCatalog.swift`
- Test: `Baby CareTests/FoodCatalogTests.swift`

**Interfaces:**
- Consumes: `Allergen` (Task 7)
- Produces: `struct FoodItem`, `enum FoodGroup`, `enum ChokingRisk`, `struct AgeBarrier`, `FoodCatalog.all: [FoodItem]`, `FoodCatalog.item(id:)`, `FoodCatalog.items(forAgeMonths:)`, `FoodCatalog.search(_:)`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/FoodCatalogTests.swift`:

```swift
import Testing
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
        #expect(honey?.ageBarrier?.reason.contains("botulizm") == true)
    }

    @Test func cowMilkAsDrinkIsBarredBeforeTwelveMonths() {
        #expect(FoodCatalog.item(id: "cow_milk_drink")?.ageBarrier?.minAgeMonths == 12)
    }

    @Test func saltIsBarredBeforeTwelveMonthsAndSugarBeforeTwentyFour() {
        #expect(FoodCatalog.item(id: "salt")?.ageBarrier?.minAgeMonths == 12)
        #expect(FoodCatalog.item(id: "added_sugar")?.ageBarrier?.minAgeMonths == 24)
    }

    @Test func everyAgeBarrierHasSourceURL() {
        for item in FoodCatalog.all {
            if let barrier = item.ageBarrier {
                #expect(barrier.sourceURL.hasPrefix("https://"),
                        "\(item.id): yaş bariyerinde kaynak linki yok")
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
                #expect(!AllergenCatalog.info(for: allergen).introductionGuidance.isEmpty)
            }
        }
    }

    @Test func ageFilterExcludesFutureFoods() {
        let sixMonthItems = FoodCatalog.items(forAgeMonths: 6)
        #expect(sixMonthItems.allSatisfy { $0.minAgeMonths <= 6 })
        #expect(sixMonthItems.contains { $0.id == "beef" })
        // Bal 12 ay bariyerli — 6 aylık listede olmamalı
        #expect(!sixMonthItems.contains { $0.id == "honey" })
    }

    @Test func searchIsCaseAndDiacriticInsensitive() {
        #expect(FoodCatalog.search("YOĞURT").contains { $0.id == "yogurt" })
        #expect(FoodCatalog.search("yogurt").contains { $0.id == "yogurt" })
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/FoodCatalogTests" -quiet
```

Beklenen: `cannot find 'FoodCatalog' in scope`.

- [ ] **Step 3: Yapıyı yaz**

`Baby Care/Core/Models/FoodCatalog.swift`:

```swift
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
/// önce önerilmez", bu "bu yaştan önce verilmez" anlamına gelir ve UI'da
/// daha ağır gösterilir.
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
    static let all: [FoodItem] = [ /* Step 4'te doldurulur */ ]

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

    static func search(_ query: String) -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter {
            $0.name.localizedStandardContains(trimmed)
                || $0.name.compare(trimmed,
                                   options: [.caseInsensitive, .diacriticInsensitive],
                                   range: nil, locale: Locale(identifier: "tr_TR")) == .orderedSame
                || $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                   locale: Locale(identifier: "tr_TR"))
                    .contains(trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive],
                                              locale: Locale(identifier: "tr_TR")))
        }
    }
}
```

- [ ] **Step 4: Besin verisini doldur**

`all` dizisine en az 60 besin eklenir. Zorunlu kapsam:

- **Demir kaynakları (en az 6):** `beef` (kırmızı et), `chicken`, `turkey`, `egg_yolk`, `lentil_red`, `chickpea`, `spinach`
- **Alerjen taşıyıcı besinler:** `yogurt` (`.milk`), `cheese_saltless` (`.milk`), `egg` (`.egg`), `peanut_butter` (`.peanut`), `tahini` (`.sesame`), `fish_seabass` (`.fish`), `shrimp` (`.shellfish`), `tofu` (`.soy`), `bulgur` / `pasta` (`.wheat`), `almond_butter` (`.treeNut`)
- **Yaş bariyerli kayıtlar (zorunlu id'ler):** `honey` (12 ay, "infantil botulizm riski"), `cow_milk_drink` (12 ay), `salt` (12 ay), `added_sugar` (24 ay), `fruit_juice` (12 ay)
- **Yüksek boğulma riski (her birinde `safePrepNote` dolu):** `grape` ("uzunlamasına dörde bölün"), `whole_nut`, `raw_carrot`, `cherry_tomato`, `sausage`
- **Sebze/meyve tabanı:** kabak, havuç (pişmiş), patates, brokoli, karnabahar, ıspanak, elma, armut, muz, avokado, şeftali, erik, kayısı
- **Tahıl:** pirinç, yulaf, bulgur, makarna, ekmek

Her kayıtta üç sunum biçimi de doldurulur. Örnek:

```swift
        FoodItem(
            id: "grape",
            name: "Üzüm",
            group: .fruit,
            minAgeMonths: 8,
            prepPuree: "Kabuğu soyulup çekirdeği çıkarıldıktan sonra ezilir.",
            prepFingerFood: "Uzunlamasına dörde bölünüp çekirdekleri çıkarılarak verilir.",
            prepFamilyMeal: "3 yaşına kadar bütün verilmez; uzunlamasına küçük parçalara ayrılır.",
            chokingRisk: .high,
            safePrepNote: "Bütün üzüm soluk borusunu tam tıkayabilir. Daima uzunlamasına dörde bölün.",
            allergen: nil,
            isIronRich: false,
            isVitaminCRich: true,
            ageBarrier: nil
        ),
        FoodItem(
            id: "honey",
            name: "Bal",
            group: .other,
            minAgeMonths: 12,
            prepPuree: "1 yaşından önce hiçbir biçimde verilmez.",
            prepFingerFood: "1 yaşından önce hiçbir biçimde verilmez.",
            prepFamilyMeal: "1 yaşından sonra az miktarda kullanılabilir.",
            chokingRisk: .low,
            safePrepNote: nil,
            allergen: nil,
            isIronRich: false,
            isVitaminCRich: false,
            ageBarrier: AgeBarrier(
                minAgeMonths: 12,
                reason: "Bal, Clostridium botulinum sporları içerebilir; bebek bağırsağında toksin oluşarak infantil botulizme yol açabilir. Pişmiş ürüne katılması bu riski ortadan kaldırmaz.",
                sourceURL: "https://hsgm.saglik.gov.tr/depo/birimler/saglikli-beslenme-ve-hareketli-hayat-db/Dokumanlar/Rehberler/Turkiye_Beslenme_Rehber_TUBER_2022_min.pdf"
            )
        ),
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/FoodCatalogTests" -quiet
```

Beklenen: 13 test PASS.

- [ ] **Step 6: Commit**

```bash
git add "Baby Care/Core/Models/FoodCatalog.swift" \
        "Baby CareTests/FoodCatalogTests.swift"
git commit -m "feat: besin kütüphanesi (TR mutfağı, 3 sunum biçimi)

Her besinde püre / parmak besin / aile yemeği sunumu, boğulma riski
sınıflandırması, alerjen bayrağı ve demir-C vitamini işareti var.
Bal, tuz, ilave şeker, inek sütü ve meyve suyu yaş bariyerli.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 9: Ek gıda veri modelleri

**Files:**
- Create: `Baby Care/Core/Models/SolidFoodRecord.swift`, `Baby Care/Core/Models/AllergenIntroduction.swift`
- Modify: `Baby Care/Baby_CareApp.swift:18-29` (şema), `Baby Care/Core/Services/BabyDeleteService.swift`
- Test: `Baby CareTests/SolidFoodModelTests.swift`

**Interfaces:**
- Consumes: `Allergen` (Task 7), `HasBabyID` protokolü (`BabyDeleteService.swift`)
- Produces: `@Model final class SolidFoodRecord`, `@Model final class AllergenIntroduction`, `enum SolidFoodMethod`, `enum SolidFoodAmount`, `enum SolidFoodReaction`, `enum AllergenStatus`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/SolidFoodModelTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Baby_Care

@MainActor
struct SolidFoodModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            Baby.self, FeedingRecord.self, SleepRecord.self, DiaperRecord.self,
            VaccinationRecord.self, GrowthRecord.self, Medication.self,
            MedicationDose.self, PediatricContact.self, BreastMilkBatch.self,
            SolidFoodRecord.self, AllergenIntroduction.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @Test func persistsSolidFoodRecord() throws {
        let context = try makeContext()
        let babyID = UUID()
        let record = SolidFoodRecord(
            babyID: babyID,
            foodIDs: ["beef", "carrot"],
            method: .puree,
            amount: .some,
            reaction: .loved,
            isFirstTry: true
        )
        context.insert(record)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SolidFoodRecord>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.foodIDs == ["beef", "carrot"])
        #expect(fetched.first?.method == .puree)
        #expect(fetched.first?.amount == .some)
        #expect(fetched.first?.reaction == .loved)
        #expect(fetched.first?.isFirstTry == true)
    }

    @Test func enumAccessorsRoundTripThroughRawValues() throws {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: [])
        record.method = .familyMeal
        record.amount = .all
        record.reaction = .adverse
        #expect(record.methodRaw == "familyMeal")
        #expect(record.amountRaw == "all")
        #expect(record.reactionRaw == "adverse")
        #expect(record.method == .familyMeal)
        #expect(record.reaction == .adverse)
    }

    @Test func unknownRawValueFallsBackSafely() throws {
        let record = SolidFoodRecord(babyID: UUID(), foodIDs: [])
        record.methodRaw = "bilinmeyen"
        record.reactionRaw = "bozuk"
        #expect(record.method == .puree)
        #expect(record.reaction == .neutral)
    }

    @Test func persistsAllergenIntroduction() throws {
        let context = try makeContext()
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .peanut)
        context.insert(intro)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AllergenIntroduction>())
        #expect(fetched.first?.allergen == .peanut)
        #expect(fetched.first?.status == .notIntroduced)
        #expect(fetched.first?.firstTriedAt == nil)
    }

    @Test func daysSinceLastServedIsNilWhenNeverServed() {
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .egg)
        #expect(intro.daysSinceLastServed == nil)
    }

    @Test func daysSinceLastServedCountsFromLastServing() {
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .egg)
        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -10, to: .now)
        #expect(intro.daysSinceLastServed == 10)
    }

    @Test func needsReminderWhenToleratedFoodNotServedForTwoWeeks() {
        // AAP 2023: tolere edilen alerjen diyette düzenli tutulmalı.
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .egg)
        intro.status = .tolerated
        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -15, to: .now)
        #expect(intro.needsRegularityReminder == true)

        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -3, to: .now)
        #expect(intro.needsRegularityReminder == false)
    }

    @Test func reactedAllergenNeverAsksForRegularity() {
        let intro = AllergenIntroduction(babyID: UUID(), allergen: .peanut)
        intro.status = .reacted
        intro.lastServedAt = Calendar.current.date(byAdding: .day, value: -60, to: .now)
        #expect(intro.needsRegularityReminder == false)
    }

    @Test func babyDeleteRemovesSolidFoodData() async throws {
        let context = try makeContext()
        let baby = Baby(name: "Test", birthDate: .now)
        context.insert(baby)
        context.insert(SolidFoodRecord(babyID: baby.id, foodIDs: ["apple"]))
        context.insert(AllergenIntroduction(babyID: baby.id, allergen: .milk))
        try context.save()

        await BabyDeleteService.delete(baby, from: context)

        #expect(try context.fetch(FetchDescriptor<SolidFoodRecord>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<AllergenIntroduction>()).isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SolidFoodModelTests" -quiet
```

Beklenen: `cannot find 'SolidFoodRecord' in scope`.

- [ ] **Step 3: `SolidFoodRecord`'u yaz**

`Baby Care/Core/Models/SolidFoodRecord.swift`:

```swift
import Foundation
import SwiftData

enum SolidFoodMethod: String, Codable, CaseIterable, Sendable {
    case puree        // geleneksel püre / ezme
    case fingerFood   // parmak besin (BLW)
    case familyMeal   // aile yemeğinden doğranmış

    var localizedTitle: String {
        switch self {
        case .puree:      return "Püre / ezme"
        case .fingerFood: return "Parmak besin"
        case .familyMeal: return "Aile yemeği"
        }
    }

    var icon: String {
        switch self {
        case .puree:      return "circle.fill"
        case .fingerFood: return "hand.raised.fingers.spread.fill"
        case .familyMeal: return "fork.knife"
        }
    }
}

/// Öğünün ne kadarının yendiği. 6-24 ay aralığında ebeveyn ml ölçmediği
/// için oransal ölçek kullanılır.
enum SolidFoodAmount: String, Codable, CaseIterable, Sendable {
    case tasted, some, most, all

    var localizedTitle: String {
        switch self {
        case .tasted: return "Tattı"
        case .some:   return "Bir kısmını yedi"
        case .most:   return "Çoğunu yedi"
        case .all:    return "Hepsini bitirdi"
        }
    }
}

enum SolidFoodReaction: String, Codable, CaseIterable, Sendable {
    case loved, neutral, refused, adverse

    var localizedTitle: String {
        switch self {
        case .loved:   return "Sevdi"
        case .neutral: return "Kararsız"
        case .refused: return "Reddetti"
        case .adverse: return "Olumsuz tepki"
        }
    }

    var icon: String {
        switch self {
        case .loved:   return "heart.fill"
        case .neutral: return "minus.circle.fill"
        case .refused: return "xmark.circle.fill"
        case .adverse: return "exclamationmark.triangle.fill"
        }
    }
}

@Model
final class SolidFoodRecord {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var servedAt: Date
    var foodIDs: [String]
    var customFoodName: String?
    var methodRaw: String
    var amountRaw: String
    var reactionRaw: String
    var isFirstTry: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var method: SolidFoodMethod {
        get { SolidFoodMethod(rawValue: methodRaw) ?? .puree }
        set { methodRaw = newValue.rawValue }
    }

    var amount: SolidFoodAmount {
        get { SolidFoodAmount(rawValue: amountRaw) ?? .some }
        set { amountRaw = newValue.rawValue }
    }

    var reaction: SolidFoodReaction {
        get { SolidFoodReaction(rawValue: reactionRaw) ?? .neutral }
        set { reactionRaw = newValue.rawValue }
    }

    /// Kayıtta yer alan katalog besinleri (bilinmeyen id'ler atlanır).
    var foods: [FoodItem] {
        foodIDs.compactMap { FoodCatalog.item(id: $0) }
    }

    /// Listelerde gösterilecek özet ad.
    var displayName: String {
        let names = foods.map(\.name)
        if let custom = customFoodName, !custom.isEmpty {
            return (names + [custom]).joined(separator: ", ")
        }
        return names.isEmpty ? "Besin belirtilmedi" : names.joined(separator: ", ")
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        servedAt: Date = .now,
        foodIDs: [String],
        customFoodName: String? = nil,
        method: SolidFoodMethod = .puree,
        amount: SolidFoodAmount = .some,
        reaction: SolidFoodReaction = .neutral,
        isFirstTry: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.servedAt = servedAt
        self.foodIDs = foodIDs
        self.customFoodName = customFoodName
        self.methodRaw = method.rawValue
        self.amountRaw = amount.rawValue
        self.reactionRaw = reaction.rawValue
        self.isFirstTry = isFirstTry
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

- [ ] **Step 4: `AllergenIntroduction`'ı yaz**

`Baby Care/Core/Models/AllergenIntroduction.swift`:

```swift
import Foundation
import SwiftData

enum AllergenStatus: String, Codable, CaseIterable, Sendable {
    case notIntroduced
    case introduced   // verildi, henüz tekrarlanmadı
    case tolerated    // sorunsuz tekrarlandı
    case reacted      // olumsuz tepki gözlendi

    var localizedTitle: String {
        switch self {
        case .notIntroduced: return "Henüz verilmedi"
        case .introduced:    return "Tanıtıldı"
        case .tolerated:     return "Sorunsuz"
        case .reacted:       return "Tepki gözlendi"
        }
    }
}

/// Bir bebeğin tek bir major alerjenle ilişkisi.
///
/// `lastServedAt` alanı AAP 2023 önerisi içindir: tolere edilen alerjen
/// diyette düzenli tutulmalıdır, tek tadım yeterli değildir.
@Model
final class AllergenIntroduction {
    @Attribute(.unique) var id: UUID
    var babyID: UUID
    var allergenRaw: String
    var statusRaw: String
    var firstTriedAt: Date?
    var lastServedAt: Date?
    var reactionNotes: String?
    var createdAt: Date
    var updatedAt: Date

    /// Tolere edilen bir alerjen bu kadar gün verilmezse hatırlatılır.
    static let regularityThresholdDays = 14

    var allergen: Allergen {
        get { Allergen(rawValue: allergenRaw) ?? .milk }
        set { allergenRaw = newValue.rawValue }
    }

    var status: AllergenStatus {
        get { AllergenStatus(rawValue: statusRaw) ?? .notIntroduced }
        set { statusRaw = newValue.rawValue }
    }

    var daysSinceLastServed: Int? {
        guard let last = lastServedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: .now).day
    }

    /// Tolere edilmiş ama uzun süredir verilmemiş alerjen için hatırlatma.
    /// Tepki gözlenmiş alerjende asla true dönmez — o besin hekim
    /// değerlendirmesi olmadan evde tekrar denenmez.
    var needsRegularityReminder: Bool {
        guard status == .tolerated, let days = daysSinceLastServed else { return false }
        return days >= Self.regularityThresholdDays
    }

    init(
        id: UUID = UUID(),
        babyID: UUID,
        allergen: Allergen,
        status: AllergenStatus = .notIntroduced,
        firstTriedAt: Date? = nil,
        lastServedAt: Date? = nil,
        reactionNotes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.babyID = babyID
        self.allergenRaw = allergen.rawValue
        self.statusRaw = status.rawValue
        self.firstTriedAt = firstTriedAt
        self.lastServedAt = lastServedAt
        self.reactionNotes = reactionNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

- [ ] **Step 5: Şemaya ve silme servisine bağla**

`Baby_CareApp.swift`, `Schema([...])` dizisine iki satır eklenir:

```swift
            BreastMilkBatch.self,
            SolidFoodRecord.self,
            AllergenIntroduction.self,
```

`Core/Services/BabyDeleteService.swift`, `delete(_:from:)` içindeki `deleteAll` çağrılarına eklenir:

```swift
        deleteAll(SolidFoodRecord.self, babyID: babyID, in: context)
        deleteAll(AllergenIntroduction.self, babyID: babyID, in: context)
```

Aynı dosyanın sonundaki uzantı listesine eklenir:

```swift
extension SolidFoodRecord:      HasBabyID {}
extension AllergenIntroduction: HasBabyID {}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SolidFoodModelTests" -quiet
```

Beklenen: 9 test PASS.

- [ ] **Step 7: Commit**

```bash
git add "Baby Care/Core/Models/SolidFoodRecord.swift" \
        "Baby Care/Core/Models/AllergenIntroduction.swift" \
        "Baby Care/Baby_CareApp.swift" \
        "Baby Care/Core/Services/BabyDeleteService.swift" \
        "Baby CareTests/SolidFoodModelTests.swift"
git commit -m "feat: ek gıda ve alerjen tanıtım veri modelleri

SolidFoodRecord ve AllergenIntroduction eklendi; FeedingRecord'a
dokunulmadı. Bebek silindiğinde her ikisi de temizleniyor.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 10: SolidFoodService — kayıt ve alerjen durumu güncelleme

Katı gıda kaydedildiğinde ilgili alerjenlerin durumu otomatik ilerlemeli. Bu mantık view'da değil, test edilebilir bir serviste yaşar.

**Files:**
- Create: `Baby Care/Core/Services/SolidFoodService.swift`
- Test: `Baby CareTests/SolidFoodServiceTests.swift`

**Interfaces:**
- Consumes: `SolidFoodRecord`, `AllergenIntroduction`, `FoodCatalog`, `Allergen` (Task 7–9)
- Produces: `SolidFoodService.log(foodIDs:customName:method:amount:reaction:servedAt:notes:for:in:) throws -> SolidFoodRecord`, `SolidFoodService.introductions(for babyID: UUID, in: ModelContext) -> [AllergenIntroduction]`, `SolidFoodService.isFirstTry(foodID:babyID:in:) -> Bool`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/SolidFoodServiceTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Baby_Care

@MainActor
struct SolidFoodServiceTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Baby.self, SolidFoodRecord.self, AllergenIntroduction.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private func makeBaby(in context: ModelContext) -> Baby {
        let eightMonthsAgo = Calendar.current.date(byAdding: .month, value: -8, to: .now)!
        let baby = Baby(name: "Test", birthDate: eightMonthsAgo)
        context.insert(baby)
        return baby
    }

    @Test func logCreatesRecord() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        let record = try SolidFoodService.log(
            foodIDs: ["beef"], method: .puree, amount: .some,
            reaction: .loved, for: baby, in: context
        )

        #expect(record.foodIDs == ["beef"])
        #expect(try context.fetch(FetchDescriptor<SolidFoodRecord>()).count == 1)
    }

    @Test func firstTryIsMarkedOnFirstServingOnly() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        let first = try SolidFoodService.log(
            foodIDs: ["carrot"], method: .puree, amount: .some,
            reaction: .loved, for: baby, in: context
        )
        let second = try SolidFoodService.log(
            foodIDs: ["carrot"], method: .puree, amount: .all,
            reaction: .loved, for: baby, in: context
        )

        #expect(first.isFirstTry == true)
        #expect(second.isFirstTry == false)
    }

    @Test func loggingAllergenFoodCreatesIntroductionRecord() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(
            foodIDs: ["yogurt"], method: .puree, amount: .some,
            reaction: .loved, for: baby, in: context
        )

        let intros = SolidFoodService.introductions(for: baby.id, in: context)
        let milk = intros.first { $0.allergen == .milk }
        #expect(milk?.status == .introduced)
        #expect(milk?.firstTriedAt != nil)
        #expect(milk?.lastServedAt != nil)
    }

    @Test func secondSuccessfulServingMarksTolerated() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)
        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .all, reaction: .neutral,
                                     for: baby, in: context)

        let milk = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .milk }
        #expect(milk?.status == .tolerated)
    }

    @Test func adverseReactionMarksReacted() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["egg"], method: .puree,
                                     amount: .tasted, reaction: .adverse,
                                     for: baby, in: context)

        let egg = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .egg }
        #expect(egg?.status == .reacted)
    }

    @Test func reactedStatusIsNotOverwrittenByLaterServing() throws {
        // Tepki gözlenmiş alerjen sonraki kayıtla "sorunsuz"a dönmez;
        // durum değişikliği hekim değerlendirmesine bağlıdır.
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["egg"], method: .puree,
                                     amount: .tasted, reaction: .adverse,
                                     for: baby, in: context)
        _ = try SolidFoodService.log(foodIDs: ["egg"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: baby, in: context)

        let egg = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .egg }
        #expect(egg?.status == .reacted)
    }

    @Test func refusedServingDoesNotAdvanceStatus() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .tasted, reaction: .refused,
                                     for: baby, in: context)

        let milk = SolidFoodService.introductions(for: baby.id, in: context)
            .first { $0.allergen == .milk }
        #expect(milk?.status == .notIntroduced)
    }

    @Test func introductionsCoverAllNineAllergens() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        let intros = SolidFoodService.introductions(for: baby.id, in: context)
        #expect(intros.count == 9)
        #expect(Set(intros.map(\.allergen)) == Set(Allergen.allCases))
    }

    @Test func introductionsAreNotDuplicatedAcrossCalls() throws {
        let context = try makeContext()
        let baby = makeBaby(in: context)

        _ = SolidFoodService.introductions(for: baby.id, in: context)
        _ = SolidFoodService.introductions(for: baby.id, in: context)

        #expect(try context.fetch(FetchDescriptor<AllergenIntroduction>()).count == 9)
    }

    @Test func introductionsAreScopedPerBaby() throws {
        let context = try makeContext()
        let first = makeBaby(in: context)
        let second = makeBaby(in: context)

        _ = try SolidFoodService.log(foodIDs: ["yogurt"], method: .puree,
                                     amount: .some, reaction: .loved,
                                     for: first, in: context)
        let secondMilk = SolidFoodService.introductions(for: second.id, in: context)
            .first { $0.allergen == .milk }
        #expect(secondMilk?.status == .notIntroduced)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SolidFoodServiceTests" -quiet
```

Beklenen: `cannot find 'SolidFoodService' in scope`.

- [ ] **Step 3: Write implementation**

`Baby Care/Core/Services/SolidFoodService.swift`:

```swift
import Foundation
import SwiftData

/// Katı gıda kaydı ve buna bağlı alerjen durumu güncellemesi.
///
/// Alerjen durumu view'da değil burada ilerler: kayıt eklendiğinde
/// besinin alerjen bayrağı okunur ve ilgili `AllergenIntroduction`
/// güncellenir.
@MainActor
enum SolidFoodService {

    @discardableResult
    static func log(
        foodIDs: [String],
        customName: String? = nil,
        method: SolidFoodMethod,
        amount: SolidFoodAmount,
        reaction: SolidFoodReaction,
        servedAt: Date = .now,
        notes: String? = nil,
        for baby: Baby,
        in context: ModelContext
    ) throws -> SolidFoodRecord {
        let firstTry = foodIDs.contains { isFirstTry(foodID: $0, babyID: baby.id, in: context) }

        let record = SolidFoodRecord(
            babyID: baby.id,
            servedAt: servedAt,
            foodIDs: foodIDs,
            customFoodName: customName,
            method: method,
            amount: amount,
            reaction: reaction,
            isFirstTry: firstTry,
            notes: notes
        )
        context.insert(record)

        updateAllergenStatus(
            foodIDs: foodIDs, reaction: reaction, servedAt: servedAt,
            babyID: baby.id, in: context
        )

        try context.save()
        return record
    }

    /// Bu besin bu bebeğe daha önce verilmiş mi.
    static func isFirstTry(foodID: String, babyID: UUID, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<SolidFoodRecord>(
            predicate: #Predicate { $0.babyID == babyID }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        return !existing.contains { $0.foodIDs.contains(foodID) }
    }

    /// Bebeğin dokuz alerjen kaydını döner; eksik olanları oluşturur.
    static func introductions(for babyID: UUID, in context: ModelContext) -> [AllergenIntroduction] {
        let descriptor = FetchDescriptor<AllergenIntroduction>(
            predicate: #Predicate { $0.babyID == babyID }
        )
        var existing = (try? context.fetch(descriptor)) ?? []
        let present = Set(existing.map(\.allergen))

        for allergen in Allergen.allCases where !present.contains(allergen) {
            let intro = AllergenIntroduction(babyID: babyID, allergen: allergen)
            context.insert(intro)
            existing.append(intro)
        }
        if existing.count != present.count { try? context.save() }

        return existing.sorted {
            Allergen.allCases.firstIndex(of: $0.allergen)!
                < Allergen.allCases.firstIndex(of: $1.allergen)!
        }
    }

    // MARK: - Private

    private static func updateAllergenStatus(
        foodIDs: [String],
        reaction: SolidFoodReaction,
        servedAt: Date,
        babyID: UUID,
        in context: ModelContext
    ) {
        let allergens = Set(foodIDs.compactMap { FoodCatalog.item(id: $0)?.allergen })
        guard !allergens.isEmpty else { return }

        let all = introductions(for: babyID, in: context)

        for allergen in allergens {
            guard let intro = all.first(where: { $0.allergen == allergen }) else { continue }

            if reaction == .adverse {
                intro.status = .reacted
                intro.firstTriedAt = intro.firstTriedAt ?? servedAt
                intro.lastServedAt = servedAt
                intro.updatedAt = .now
                continue
            }

            // Tepki gözlenmiş alerjen kendiliğinden "sorunsuz"a dönmez —
            // bu karar hekimindir.
            if intro.status == .reacted { continue }

            // Reddedilen öğün besin alınmadığı anlamına gelir; durumu ilerletmez.
            guard reaction != .refused else { continue }

            switch intro.status {
            case .notIntroduced:
                intro.status = .introduced
                intro.firstTriedAt = servedAt
            case .introduced:
                intro.status = .tolerated
            case .tolerated, .reacted:
                break
            }
            intro.lastServedAt = servedAt
            intro.updatedAt = .now
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SolidFoodServiceTests" -quiet
```

Beklenen: 10 test PASS.

- [ ] **Step 5: Commit**

```bash
git add "Baby Care/Core/Services/SolidFoodService.swift" \
        "Baby CareTests/SolidFoodServiceTests.swift"
git commit -m "feat: SolidFoodService — kayıt ve alerjen durumu ilerlemesi

Alerjen durumu kayıttan otomatik ilerliyor: verildi → sorunsuz.
Olumsuz tepki 'tepki gözlendi'de kilitleniyor, sonraki kayıtla
geri dönmüyor — bu karar hekimin.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 11: Takip sekmesi entegrasyonu

**Files:**
- Create: `Baby Care/Features/SolidFood/SolidFoodAddSheet.swift`
- Modify: `Baby Care/Features/Tracking/TrackingView.swift`
- Test: `Baby CareTests/SolidFoodSummaryTests.swift`

**Interfaces:**
- Consumes: `SolidFoodService.log(...)` (Task 10), `BabyStage` (Task 1), `FoodCatalog.items(forAgeMonths:)` (Task 8)
- Produces:
  - `SolidFoodAddSheet(baby: Baby, editing: SolidFoodRecord? = nil)` — `FeedingAddSheet` yalnız `babyID` alıyor, ama bu sheet yaş bariyeri uyarısı için bebeğin yaşına ihtiyaç duyuyor; bu yüzden `Baby`'nin kendisini alır. Task 12 ve Task 13 bu imzayı kullanır.
  - `SolidFoodDaySummary.make(from records: [SolidFoodRecord]) -> SolidFoodDaySummary` — alanlar: `mealCount: Int`, `firstTryCount: Int`, `detailText: String`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/SolidFoodSummaryTests.swift`:

```swift
import Testing
import Foundation
@testable import Baby_Care

struct SolidFoodSummaryTests {

    @Test func emptyDayShowsDash() {
        let summary = SolidFoodDaySummary.make(from: [])
        #expect(summary.mealCount == 0)
        #expect(summary.detailText == "—")
    }

    @Test func countsMealsAndFirstTries() {
        let babyID = UUID()
        let records = [
            SolidFoodRecord(babyID: babyID, foodIDs: ["carrot"], isFirstTry: true),
            SolidFoodRecord(babyID: babyID, foodIDs: ["apple"], isFirstTry: false),
            SolidFoodRecord(babyID: babyID, foodIDs: ["beef"], isFirstTry: true)
        ]
        let summary = SolidFoodDaySummary.make(from: records)
        #expect(summary.mealCount == 3)
        #expect(summary.firstTryCount == 2)
        #expect(summary.detailText == "2 yeni besin")
    }

    @Test func singleFirstTryUsesSingularPhrasing() {
        let records = [SolidFoodRecord(babyID: UUID(), foodIDs: ["pear"], isFirstTry: true)]
        #expect(SolidFoodDaySummary.make(from: records).detailText == "1 yeni besin")
    }

    @Test func noFirstTryShowsMealWord() {
        let records = [SolidFoodRecord(babyID: UUID(), foodIDs: ["pear"], isFirstTry: false)]
        #expect(SolidFoodDaySummary.make(from: records).detailText == "yeni besin yok")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SolidFoodSummaryTests" -quiet
```

Beklenen: `cannot find 'SolidFoodDaySummary' in scope`.

- [ ] **Step 3: Özet tipini yaz**

`Baby Care/Core/Models/SolidFoodRecord.swift` dosyasının sonuna eklenir (kayıtla birlikte değişir, birlikte yaşar):

```swift
/// Takip ekranındaki günlük ek gıda özet kartının verisi.
struct SolidFoodDaySummary: Sendable {
    let mealCount: Int
    let firstTryCount: Int

    var detailText: String {
        if mealCount == 0 { return "—" }
        return firstTryCount > 0 ? "\(firstTryCount) yeni besin" : "yeni besin yok"
    }

    static func make(from records: [SolidFoodRecord]) -> SolidFoodDaySummary {
        SolidFoodDaySummary(
            mealCount: records.count,
            firstTryCount: records.filter(\.isFirstTry).count
        )
    }
}
```

- [ ] **Step 4: `SolidFoodAddSheet`'i yaz**

`Baby Care/Features/SolidFood/SolidFoodAddSheet.swift`. `FeedingAddSheet` desenini izler: `NavigationStack` + `Form`, `@Environment(\.dismiss)`, kaydet/vazgeç toolbar'ı, hata için `errorMessage` state'i.

Form bölümleri:
1. **Besin** — seçilen besinlerin listesi + `FoodLibraryView`'a giden "Besin ekle" satırı (Task 12'de gelir; bu görevde geçici olarak arama alanlı basit bir `Picker` kullanılır ve Task 12'de bağlanır). Katalog dışı besin için `TextField`.
2. **Sunum** — `Picker` (`SolidFoodMethod.allCases`, `.segmented`)
3. **Zaman** — `DatePicker`
4. **Ne kadar yedi** — `Picker` (`SolidFoodAmount.allCases`, `.menu`)
5. **Tepki** — `Picker` (`SolidFoodReaction.allCases`, `.menu`)
6. **Not** — `TextField`

Yaş bariyeri uyarısı: seçilen besinlerden birinin `ageBarrier.minAgeMonths` değeri bebeğin yaşından büyükse, formun üstünde turuncu bir uyarı satırı gösterilir ve bariyerin `reason` metni ile kaynak linki verilir. **Kaydetme engellenmez** (Global Constraints).

`reaction == .adverse` seçilirse formun altında kırmızı bir uyarı ve "Alerjik reaksiyon belirtileri" ekranına `NavigationLink` gösterilir (hedef Task 13'te gelir; o zamana kadar link gizlenir).

Kaydetme `SolidFoodService.log(...)` çağırır, `Haptics.success()` ile biter.

- [ ] **Step 5: `TrackingView`'a bağla**

`Features/Tracking/TrackingView.swift`:

- `@Query(sort: \SolidFoodRecord.servedAt, order: .reverse) private var allSolids: [SolidFoodRecord]` eklenir.
- `todaysSolids` hesaplanan property'si `todaysFeedings` desenini izler (`babyID` + `isDate(_:inSameDayAs:)`).
- `summaryRow` içine dördüncü kart eklenir; yalnız `baby?.stage.isSolidFoodAge == true` iken görünür:

```swift
                if baby?.stage.isSolidFoodAge == true {
                    let solidSummary = SolidFoodDaySummary.make(from: todaysSolids)
                    summaryCard(
                        icon: "carrot.fill",
                        color: .orange,
                        title: "Ek Gıda",
                        primary: "\(solidSummary.mealCount) öğün",
                        secondary: solidSummary.detailText
                    )
                }
```

Dört kart tek satıra sığmayacağı için `summaryRow`'daki `HStack` iki satırlık bir `Grid`'e dönüştürülür (2×2). Üç kart varken (6 ay altı) tek satır görünümü korunur.

- `quickAddRow`'a "Ek Gıda" butonu eklenir (aynı yaş koşuluyla), `showSolidSheet` state'ini açar.
- `recentActivitiesSection` listesine katı gıda satırları eklenir; satır `record.displayName` + `method.localizedTitle` + `reaction.icon` gösterir.
- `.sheet(isPresented: $showSolidSheet)` ve `.sheet(item: $editingSolid)` eklenir.

- [ ] **Step 6: Run tests and build**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests" -quiet
```

Beklenen: tüm testler PASS ve proje derleniyor.

- [ ] **Step 7: Simülatörde görsel doğrulama**

8 aylık doğum tarihli bir bebek oluştur, Takip sekmesinde Ek Gıda kartının göründüğünü ve kayıt eklenebildiğini doğrula. 2 aylık bir bebekte kartın **görünmediğini** doğrula.

- [ ] **Step 8: Commit**

```bash
git add "Baby Care/Features/SolidFood/SolidFoodAddSheet.swift" \
        "Baby Care/Features/Tracking/TrackingView.swift" \
        "Baby Care/Core/Models/SolidFoodRecord.swift" \
        "Baby CareTests/SolidFoodSummaryTests.swift"
git commit -m "feat: Takip sekmesinde ek gıda kaydı

6 ay ve üzeri bebeklerde ek gıda özet kartı, hızlı ekleme ve
gün listesinde katı gıda satırları. Yaş bariyerli besinde uyarı
gösteriliyor ama kayıt engellenmiyor.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 12: Ek Gıda ekranı

**Files:**
- Create: `Baby Care/Features/SolidFood/SolidFoodView.swift`, `FoodLibraryView.swift`, `FoodDetailView.swift`, `AllergenPanelView.swift`
- Modify: `Baby Care/Features/Profile/BabyProfileView.swift:31-79` ("Detaylar" bölümü)
- Modify: `Baby Care/Features/SolidFood/SolidFoodAddSheet.swift` (besin seçimini `FoodLibraryView`'a bağla)

**Interfaces:**
- Consumes: `FoodCatalog`, `AllergenCatalog`, `SolidFoodService.introductions(for:in:)`, `GuideCatalog.stage(forAgeWeeks:)`
- Produces: `SolidFoodView(baby:)`, `FoodLibraryView(baby:selection:)`, `FoodDetailView(item:baby:)`, `AllergenPanelView(baby:)`

Bu görev tamamen görünüm katmanıdır; iş mantığı Task 8–10'da test edildi. Burada birim testi yerine simülatör doğrulaması yapılır.

- [ ] **Step 1: `FoodLibraryView`'ı yaz**

Arama alanı (`.searchable`), grup ve alerjen filtresi, `FoodCatalog.items(forAgeMonths: baby.ageInMonths)` sonucunu listeleyen `List`. Her satırda besin adı, grup rozeti, yüksek boğulma riski varsa turuncu üçgen ikonu. Seçim modunda (`selection` binding'i verildiğinde) çoklu seçim yapılabilir ve `SolidFoodAddSheet`'e döner.

Boş durum: filtre sonucu boşsa `ContentUnavailableView` ile "Bu filtrede besin yok" gösterilir.

- [ ] **Step 2: `FoodDetailView`'ı yaz**

Tek besin kartı. Bölümler:
- Üç sunum biçimi (püre / parmak besin / aile yemeği), `SolidFoodMethod` ikonlarıyla
- Boğulma riski rozeti + `safePrepNote` (varsa)
- Alerjen bilgisi (varsa): `AllergenCatalog.info(for:)` içeriği + kaynak linki
- Yaş bariyeri (varsa): kırmızı bölüm, `reason` metni + kaynak linki
- Demir / C vitamini işaretleri
- Alt bilgi: "Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz."

- [ ] **Step 3: `AllergenPanelView`'ı yaz**

`SolidFoodService.introductions(for:in:)` sonucunu dokuz satır hâlinde listeler. Her satırda alerjen adı, durum rozeti (`AllergenStatus.localizedTitle`) ve `needsRegularityReminder` true ise "X gündür verilmedi" uyarısı.

Satıra dokunulduğunda `AllergenCatalog.info(for:)` içeriğini gösteren detay: tanıtım rehberi, güvenli sunum biçimi, kaynak linki.

Panelin üstünde tek seferlik açıklama bloğu (K-02'nin görünür karşılığı):

> Güncel uluslararası kılavuzlar (ESPGHAN, AAP, EAACI) alerjenlerin geciktirilmemesini, tamamlayıcı beslenmeyle birlikte yaklaşık 6. ayda tanıtılmasını öneriyor. T.C. Sağlık Bakanlığı Türkiye Beslenme Rehberi ise yeni besinler arasında 3–5 gün bırakılmasını öneriyor; bunu gözlem için tercih edebilirsiniz. Her iki kaynağa da aşağıdan ulaşabilirsiniz.

Altında iki tıklanabilir link: ESPGHAN kılavuz özeti ve TÜBER 2022.

- [ ] **Step 4: `SolidFoodView`'ı yaz**

Üç bölümlü `TabView` (`.page` değil, segmented `Picker` ile bölüm değiştirme — mevcut uygulamada `TabView` yalnız kök seviyede kullanılıyor):

1. **Rehber** — `GuideCatalog.stage(forAgeWeeks: baby.ageInWeeks)` aşamasının `feedingTips` listesi + kıvam/öğün/porsiyon özeti
2. **Besinler** — `FoodLibraryView`
3. **Alerjenler** — `AllergenPanelView`

- [ ] **Step 5: `BabyProfileView`'a bağla**

"Detaylar" bölümüne, "Beslenme Hesabı" satırının hemen üstüne eklenir; yalnız `baby.stage.isSolidFoodAge` iken görünür:

```swift
                        if baby.stage.isSolidFoodAge {
                            NavigationLink {
                                SolidFoodView(baby: baby)
                            } label: {
                                Label("Ek Gıda", systemImage: "carrot.fill")
                            }
                        }
```

- [ ] **Step 6: `SolidFoodAddSheet`'in besin seçimini bağla**

Task 11'de geçici olan `Picker`, `FoodLibraryView(baby:selection:)`'a giden `NavigationLink` ile değiştirilir.

- [ ] **Step 7: Derle ve simülatörde doğrula**

```bash
xcodebuild build -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -quiet
```

Simülatörde: 8 aylık bebekte Bebek sekmesinden Ek Gıda ekranını aç, üç bölümü de gez, bir besinin detayına gir, alerjen panelinde durum değişimini kayıt ekleyerek doğrula. Açık ve koyu temada kontrastı kontrol et.

- [ ] **Step 8: Commit**

```bash
git add "Baby Care/Features/SolidFood" "Baby Care/Features/Profile/BabyProfileView.swift"
git commit -m "feat: Ek Gıda ekranı — rehber, besin kütüphanesi, alerjen paneli

Üç bölüm: yaşa göre beslenme rehberi, aranabilir besin kütüphanesi
(boğulma riski ve sunum biçimleriyle) ve 9 alerjenlik durum paneli.
Alerjen panelinde iki kaynak yan yana sunuluyor.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 13: Güvenlik içeriği — öğürme ayrımı, 1 yaş üstü boğulma, adrenalin

Bu görev sıfırdan içerik yazmaz. `FirstAidCatalog` içinde **zaten** `choking` (bebek boğulması) ve `allergy` (alerjik reaksiyon) senaryoları var ve kaliteli. Ek gıda dönemi için üç gerçek boşluk kapatılır:

1. **Öğürme (gag) ile boğulma (choking) ayrımı yok.** Ek gıdaya başlayan ebeveynin en sık panikleyip yanlış müdahale ettiği nokta budur — öğüren bebeğe sırt vuruşu yapmak zararlıdır.
2. **1 yaş üstü müdahale yok.** Mevcut senaryo yalnız bebek için (sırt vuruşu + göğüs basısı) ve uyarılarında "Heimlich bebeklerde kullanılmaz" diyor — doğru, ama 12–24 ayda karın baskısı uygulanır. Uygulama artık 24 ayı kapsadığı için bu eksik.
3. **Adrenalin oto-enjektörü hiç geçmiyor.** Mevcut `allergy` senaryosu antihistaminiği doğru biçimde yasaklıyor ama reçeteli adrenalinden söz etmiyor.

Ayrıca `SymptomCatalog`'da alerjik reaksiyon kategorisi yok; "Bu Normal Mi?" akışından ulaşılamıyor.

**Files:**
- Modify: `Baby Care/Core/Models/FirstAidCatalog.swift`
- Modify: `Baby Care/Core/Models/SymptomCatalog.swift`
- Modify: `Baby Care/Features/SolidFood/SolidFoodAddSheet.swift` (olumsuz tepki kısayolunu aktif et)
- Test: `Baby CareTests/SafetyContentTests.swift`

**Interfaces:**
- Consumes (mevcut, değişmiyor): `FirstAidScenario(id:title:icon:color:summary:callEmergency:callEmergencyWhen:steps:warnings:)`, `FirstAidStep(id:title:detail:)`, `FirstAidCatalog.scenarios: [FirstAidScenario]`, `SymptomCategory(id:title:icon:color:prompt:scenarios:)`, `SymptomScenario(id:label:urgency:advice:nextSteps:)`, `Urgency` (`.normal` / `.warning` / `.emergency`), `SymptomCatalog.categories: [SymptomCategory]`
- Produces: `FirstAidCatalog.chokingToddler` (yeni senaryo, id `"choking_toddler"`), `SymptomCatalog` içinde `"allergic_reaction"` id'li kategori

- [ ] **Step 1: Write the failing test**

`Baby CareTests/SafetyContentTests.swift`:

```swift
import Testing
@testable import Baby_Care

struct SafetyContentTests {

    // MARK: - Boğulma

    @Test func infantChokingScenarioStillExists() {
        #expect(FirstAidCatalog.scenarios.contains { $0.id == "choking" })
    }

    @Test func toddlerChokingScenarioIsAdded() {
        let toddler = FirstAidCatalog.scenarios.first { $0.id == "choking_toddler" }
        #expect(toddler != nil)
        #expect(toddler?.steps.isEmpty == false)
    }

    @Test func toddlerChokingUsesAbdominalThrusts() {
        // 1 yaş üstünde karın baskısı uygulanır; bebekte uygulanmaz.
        let toddler = FirstAidCatalog.scenarios.first { $0.id == "choking_toddler" }!
        let text = toddler.steps.map { $0.title + " " + ($0.detail ?? "") }
            .joined(separator: " ")
        #expect(text.contains("karın") || text.contains("Karın"))
    }

    @Test func infantChokingStillForbidsAbdominalThrusts() {
        let infant = FirstAidCatalog.scenarios.first { $0.id == "choking" }!
        let warnings = infant.warnings.joined(separator: " ")
        #expect(warnings.contains("Heimlich"))
    }

    @Test func gaggingIsDistinguishedFromChoking() {
        // Öğüren bebeğe müdahale edilmez; bu ayrım her iki senaryoda da olmalı.
        for id in ["choking", "choking_toddler"] {
            let scenario = FirstAidCatalog.scenarios.first { $0.id == id }!
            let text = ([scenario.summary] + scenario.warnings
                        + scenario.steps.map { $0.title + " " + ($0.detail ?? "") })
                .joined(separator: " ")
            #expect(text.localizedCaseInsensitiveContains("öğür"),
                    "\(id): öğürme/boğulma ayrımı yok")
        }
    }

    @Test func bothChokingScenariosCallEmergency() {
        for id in ["choking", "choking_toddler"] {
            let scenario = FirstAidCatalog.scenarios.first { $0.id == id }!
            #expect(scenario.callEmergency == true, "\(id): 112 çağrısı işaretli değil")
        }
    }

    // MARK: - Alerji

    @Test func allergyScenarioMentionsEpinephrine() {
        // AAP acil planı: reçeteli adrenalin gecikmeden uygulanır.
        let allergy = FirstAidCatalog.scenarios.first { $0.id == "allergy" }!
        let text = (allergy.steps.map { $0.title + " " + ($0.detail ?? "") }
                    + allergy.warnings).joined(separator: " ")
        #expect(text.localizedCaseInsensitiveContains("adrenalin"))
    }

    @Test func allergyScenarioStillWarnsAgainstAntihistamineSubstitution() {
        let allergy = FirstAidCatalog.scenarios.first { $0.id == "allergy" }!
        let warnings = allergy.warnings.joined(separator: " ")
        #expect(warnings.localizedCaseInsensitiveContains("antihistamin"))
    }

    // MARK: - Semptom kategorisi

    @Test func allergicReactionCategoryExists() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }
        #expect(category != nil)
        #expect(category?.scenarios.isEmpty == false)
    }

    @Test func allergicReactionCategoryCoversAllThreeUrgencyLevels() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        let levels = Set(category.scenarios.map(\.urgency))
        #expect(levels.contains(.normal) || levels.contains(.warning))
        #expect(levels.contains(.emergency))
    }

    @Test func anaphylaxisScenarioIsEmergency() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        let anaphylaxis = category.scenarios.first { $0.id == "allergy_anaphylaxis" }
        #expect(anaphylaxis != nil)
        #expect(anaphylaxis?.urgency == .emergency)
    }

    @Test func anaphylaxisAdviceMentionsEpinephrineAndEmergencyNumber() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        let anaphylaxis = category.scenarios.first { $0.id == "allergy_anaphylaxis" }!
        let text = ([anaphylaxis.advice] + anaphylaxis.nextSteps).joined(separator: " ")
        #expect(text.localizedCaseInsensitiveContains("adrenalin"))
        #expect(text.contains("112"))
    }

    @Test func everyAllergicScenarioHasNextSteps() {
        let category = SymptomCatalog.categories.first { $0.id == "allergic_reaction" }!
        for scenario in category.scenarios {
            #expect(!scenario.label.isEmpty, "\(scenario.id): etiket boş")
            #expect(!scenario.advice.isEmpty, "\(scenario.id): öneri boş")
            #expect(!scenario.nextSteps.isEmpty, "\(scenario.id): adım listesi boş")
        }
    }

    @Test func scenarioIdentifiersRemainUnique() {
        let firstAidIDs = FirstAidCatalog.scenarios.map(\.id)
        #expect(Set(firstAidIDs).count == firstAidIDs.count)
        let categoryIDs = SymptomCatalog.categories.map(\.id)
        #expect(Set(categoryIDs).count == categoryIDs.count)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SafetyContentTests" -quiet
```

Beklenen: `choking_toddler` ve `allergic_reaction` bulunamadığı için FAIL; öğürme ve adrenalin testleri de FAIL.

- [ ] **Step 3: Mevcut `choking` senaryosuna öğürme ayrımını ekle**

`FirstAidCatalog.swift`, `choking` senaryosunda `summary` değiştirilir ve `steps` listesinin **başına** bir adım eklenir (kalan adımların `id` değerleri birer artar):

```swift
        summary: "Bebek bir cisim ile boğuluyor (nefes alamıyor, ağlamıyor, mavi/mor renk). Öğürme ile karıştırmayın.",
```

```swift
        steps: [
            .init(id: 1, title: "Önce öğürme mü, boğulma mı ayırt edin",
                  detail: "Öğürmede bebek ses çıkarır, öksürür, yüzü kızarır — bu koruyucu bir reflekstir ve ek gıda döneminde sık görülür. Bekleyin, sırta vurmayın. Boğulmada ses yoktur: öksüremez, nefes alamaz, rengi morarır. Aşağıdaki adımlar yalnız boğulma içindir."),
            .init(id: 2, title: "112'yi arayın", detail: "Mümkünse hoparlöre alın; iki elinizi serbest tutun."),
            // ... kalan adımlar id 3'ten devam eder
        ],
```

`warnings` listesine eklenir:

```swift
            "Öğüren bebeğe sırt vuruşu veya bası UYGULAMAYIN — öksürük en etkili temizleyicidir."
```

- [ ] **Step 4: 1 yaş üstü boğulma senaryosunu ekle**

`FirstAidCatalog.swift`, `choking` senaryosunun hemen altına:

```swift
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
            "Bütün üzüm, fındık ve sert şeker 3 yaşına kadar bu riskin en sık nedenleridir."
        ]
    )
```

`scenarios` dizisine eklenir (bebek boğulmasının hemen ardından):

```swift
    static let scenarios: [FirstAidScenario] = [
        choking, chokingToddler, cpr, fever, fall, burn, drowning, noseBlock, allergy
    ]
```

- [ ] **Step 5: `allergy` senaryosuna adrenalini ekle**

`FirstAidCatalog.swift`, `allergy` senaryosunda 1. adımdan sonra yeni adım eklenir (sonraki adımların `id` değerleri birer artar):

```swift
            .init(id: 2, title: "Reçeteli adrenaliniz varsa hemen uygulayın",
                  detail: "Çocuğunuz için daha önce adrenalin oto-enjektörü reçete edildiyse, anafilaksi belirtilerinde beklemeden uyluğun ön-yan yüzüne uygulayın. Belirtiler 5 dakikada düzelmezse ikinci doz gerekebilir — 112 ekibiyle konuşun."),
```

`warnings` listesindeki antihistaminik uyarısı korunur, yanına eklenir:

```swift
            "Antihistaminik yalnızca deri belirtilerini azaltabilir; adrenalinin YERİNE GEÇMEZ.",
```

- [ ] **Step 6: `SymptomCatalog`'a alerjik reaksiyon kategorisini ekle**

`SymptomCatalog.swift`, `categories` dizisine yeni kategori eklenir (`feeding` kategorisinin ardından):

```swift
    static let allergicReaction = SymptomCategory(
        id: "allergic_reaction",
        title: "Alerjik Reaksiyon",
        icon: "allergens.fill",
        color: .pink,
        prompt: "Yeni bir besinden sonra ortaya çıkan belirtiler. Reaksiyonların çoğu ilk iki saat içinde başlar.",
        scenarios: [
            .init(id: "allergy_mild",
                  label: "Ağız çevresinde birkaç kabarıklık veya kızarıklık",
                  urgency: .warning,
                  advice: "Besini durdurun ve bebeği yakından izleyin. Belirti yayılırsa veya ikinci bir sistem eklenirse (solunum, kusma) anafilaksi gibi davranın.",
                  nextSteps: [
                    "Verdiğiniz besini ve saati not edin.",
                    "Aynı besini hekiminize danışmadan tekrar vermeyin.",
                    "Bebeği en az iki saat gözlemleyin.",
                    "Doktorunuz önermeden ilaç vermeyin."
                  ]),
            .init(id: "allergy_widespread_hives",
                  label: "Vücuda yayılan kurdeşen (ürtiker)",
                  urgency: .warning,
                  advice: "Tek başına yaygın döküntü acil olmayabilir, ancak hızla ilerleyebilir. Bugün hekime başvurun.",
                  nextSteps: [
                    "Solunum ve yutmayı sürekli kontrol edin.",
                    "Döküntünün fotoğrafını çekin — hekim için değerlidir.",
                    "Nefes darlığı, hırıltı veya şişme eklenirse hemen 112."
                  ]),
            .init(id: "allergy_vomiting",
                  label: "Yeni besinden sonra tekrarlayan kusma veya ağır ishal",
                  urgency: .warning,
                  advice: "Sindirim sistemi bulguları tek başına da alerjik reaksiyon olabilir. Hekime başvurun.",
                  nextSteps: [
                    "Sıvı kaybı belirtilerini izleyin: az ıslak bez, ağız kuruluğu, halsizlik.",
                    "Besini durdurun, hekiminize danışmadan tekrar vermeyin.",
                    "Halsizlik veya solukluk eklenirse hemen 112."
                  ]),
            .init(id: "allergy_anaphylaxis",
                  label: "Nefes darlığı, hırıltı, dudak-dil şişmesi veya ani halsizlik",
                  urgency: .emergency,
                  advice: "Bu anafilaksi olabilir. HEMEN 112'yi arayın. Reçeteli adrenalin oto-enjektörünüz varsa beklemeden uygulayın — antihistaminik adrenalinin yerine geçmez.",
                  nextSteps: [
                    "112'yi arayın; beklemeyin.",
                    "Reçeteli adrenalini uyluğun ön-yan yüzüne uygulayın.",
                    "Bebeği sırtüstü yatırın; kusuyorsa yan çevirin. Ayağa kaldırmayın.",
                    "Belirtiler 5 dakikada düzelmezse ikinci doz için 112 ekibiyle konuşun.",
                    "Düzelmiş görünse bile acil serviste değerlendirilmelidir."
                  ])
        ]
    )
```

Kategori `categories` dizisine eklenir. Dosya sonundaki kaynak yorumuna AAP acil planı linki eklenir:
`https://downloads.aap.org/HC/AAP_Allergy_and_Anaphylaxis_Emergency_Plan.pdf`

- [ ] **Step 7: `SolidFoodAddSheet` kısayolunu aktif et**

Task 11'de gizli bırakılan link açılır. `reaction == .adverse` seçildiğinde form altında kırmızı bir bölüm görünür ve `SymptomDetailView`'a `allergicReaction` kategorisiyle yönlendirir. `SymptomDetailView`'ın init imzası `Features/Health/SymptomDetailView.swift` dosyasından okunup ona göre çağrılır.

- [ ] **Step 8: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/SafetyContentTests" -quiet
```

Beklenen: 14 test PASS.

- [ ] **Step 9: Commit**

```bash
git add "Baby Care/Core/Models/FirstAidCatalog.swift" \
        "Baby Care/Core/Models/SymptomCatalog.swift" \
        "Baby Care/Features/SolidFood/SolidFoodAddSheet.swift" \
        "Baby CareTests/SafetyContentTests.swift"
git commit -m "feat: ek gıda dönemi güvenlik içeriği

Üç boşluk kapatıldı: öğürme ile boğulma ayrımı (ek gıdada en sık
karıştırılan durum), 1 yaş üstü boğulma müdahalesi (karın baskısı)
ve alerjik reaksiyonda reçeteli adrenalin. Semptom kataloğuna
alerjik reaksiyon kategorisi eklendi.

Kaynak: AAP Allergy and Anaphylaxis Emergency Plan.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 14: Yedekleme v2

Yeni alanlar zorunlu yapılırsa `try? decoder.decode` v1 yedeklerinde nil döner ve kullanıcı "dosya bozuk" hatası alır. Bu görevin asıl amacı o regresyonu testle kilitlemek.

**Files:**
- Modify: `Baby Care/Core/Services/DataBackupService.swift`
- Test: `Baby CareTests/BackupCompatibilityTests.swift`

**Interfaces:**
- Consumes: `SolidFoodRecord`, `AllergenIntroduction` (Task 9)
- Produces: `DataBackupService.currentVersion = 2`, `struct SolidFoodExport: Codable`, `struct AllergenIntroductionExport: Codable`, `DataExportPackage.solidFoods: [SolidFoodExport]?`, `DataExportPackage.allergenIntroductions: [AllergenIntroductionExport]?`

- [ ] **Step 1: Write the failing test**

`Baby CareTests/BackupCompatibilityTests.swift`:

```swift
import Testing
import Foundation
@testable import Baby_Care

struct BackupCompatibilityTests {

    /// Sürüm 1 formatında, yeni alanları içermeyen bir yedek.
    private let v1JSON = """
    {
      "version": 1,
      "exportedAt": "2026-01-15T10:00:00Z",
      "appVersion": "1.4.1",
      "babies": [{
        "id": "11111111-1111-1111-1111-111111111111",
        "name": "Deniz",
        "birthDate": "2025-08-01T00:00:00Z",
        "sex": "female",
        "createdAt": "2025-08-01T00:00:00Z",
        "updatedAt": "2025-08-01T00:00:00Z"
      }],
      "feedings": [], "sleeps": [], "diapers": [], "vaccinations": [],
      "growth": [], "medications": [], "medicationDoses": [],
      "milkBatches": [], "pediatricContacts": []
    }
    """

    @Test func versionIsTwo() {
        #expect(DataBackupService.currentVersion == 2)
    }

    @Test func decodesVersionOnePackageWithoutNewFields() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let package = try decoder.decode(
            DataExportPackage.self, from: Data(v1JSON.utf8)
        )

        #expect(package.version == 1)
        #expect(package.babies.count == 1)
        #expect(package.solidFoods == nil)
        #expect(package.allergenIntroductions == nil)
    }

    @Test func versionOnePackageIsNotRejectedAsIncompatible() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let package = try decoder.decode(
            DataExportPackage.self, from: Data(v1JSON.utf8)
        )
        // Import yalnız package.version > currentVersion ise reddeder.
        #expect(package.version <= DataBackupService.currentVersion)
    }

    @Test func newExportRoundTripsSolidFoodData() throws {
        let babyID = UUID()
        let package = DataExportPackage(
            version: DataBackupService.currentVersion,
            exportedAt: .now,
            appVersion: "1.5",
            babies: [], feedings: [], sleeps: [], diapers: [],
            vaccinations: [], growth: [], medications: [],
            medicationDoses: [], milkBatches: [], pediatricContacts: [],
            solidFoods: [SolidFoodExport(
                id: UUID(), babyID: babyID, servedAt: .now,
                foodIDs: ["beef", "carrot"], customFoodName: nil,
                method: "puree", amount: "some", reaction: "loved",
                isFirstTry: true, notes: nil, createdAt: .now, updatedAt: .now
            )],
            allergenIntroductions: [AllergenIntroductionExport(
                id: UUID(), babyID: babyID, allergen: "egg",
                status: "tolerated", firstTriedAt: .now, lastServedAt: .now,
                reactionNotes: nil, createdAt: .now, updatedAt: .now
            )]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(package)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DataExportPackage.self, from: data)

        #expect(decoded.solidFoods?.count == 1)
        #expect(decoded.solidFoods?.first?.foodIDs == ["beef", "carrot"])
        #expect(decoded.allergenIntroductions?.first?.allergen == "egg")
        #expect(decoded.allergenIntroductions?.first?.status == "tolerated")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/BackupCompatibilityTests" -quiet
```

Beklenen: `SolidFoodExport` yok — derleme hatası.

- [ ] **Step 3: DTO'ları ve sürümü ekle**

`DataBackupService.swift`. `DataExportPackage`'a iki **optional** alan eklenir (mevcut alanların sırası korunur):

```swift
    let pediatricContacts: [PediatricContactExport]
    /// Sürüm 2'de eklendi. Sürüm 1 yedeklerinde bulunmadığı için optional —
    /// zorunlu yapılırsa eski yedekler decode edilemez hâle gelir.
    let solidFoods: [SolidFoodExport]?
    let allergenIntroductions: [AllergenIntroductionExport]?
```

Yeni DTO'lar:

```swift
struct SolidFoodExport: Codable {
    let id: UUID
    let babyID: UUID
    let servedAt: Date
    let foodIDs: [String]
    let customFoodName: String?
    let method: String
    let amount: String
    let reaction: String
    let isFirstTry: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct AllergenIntroductionExport: Codable {
    let id: UUID
    let babyID: UUID
    let allergen: String
    let status: String
    let firstTriedAt: Date?
    let lastServedAt: Date?
    let reactionNotes: String?
    let createdAt: Date
    let updatedAt: Date
}
```

`currentVersion` 2 olur. `export` fonksiyonunda iki yeni fetch ve `makeExport` eşlemesi eklenir; `import` fonksiyonunda `package.solidFoods ?? []` ve `package.allergenIntroductions ?? []` üzerinden `toModel()` çağrılır. `makeExport(_:)` ve `toModel()` uzantıları mevcut desenle aynı biçimde yazılır.

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/BackupCompatibilityTests" -quiet
```

Beklenen: 4 test PASS.

- [ ] **Step 5: Simülatörde uçtan uca doğrula**

Ek gıda kaydı olan bir profilden yedek al, uygulamayı sıfırla, yedeği geri yükle, ek gıda ve alerjen kayıtlarının döndüğünü doğrula.

- [ ] **Step 6: Commit**

```bash
git add "Baby Care/Core/Services/DataBackupService.swift" \
        "Baby CareTests/BackupCompatibilityTests.swift"
git commit -m "feat: yedekleme sürüm 2 — ek gıda ve alerjen kayıtları

Yeni alanlar optional; sürüm 1 yedekleri geri yüklenmeye devam
ediyor. Bu davranış testle kilitlendi.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 15: Özet, rapor ve konumlandırma

**Files:**
- Modify: `Baby Care/Core/Services/WeeklySummaryCalculator.swift`, `Baby Care/Core/Services/PDFReportGenerator.swift`, `Baby Care/Features/Profile/PDFReportView.swift`, `Baby Care/Features/Home/DashboardView.swift`, `Baby Care/Features/Household/SettingsView.swift`
- Modify: `docs/APP_STORE_TR.md`, `docs/APP_STORE_EN.md`, `docs/APP_STORE_REVIEW_NOTES.md`
- Test: `Baby CareTests/WeeklySummarySolidFoodTests.swift`

**Interfaces:**
- Consumes: `SolidFoodRecord`, `AllergenIntroduction`, `BabyStage`
- Produces: `WeeklySummary.solidFoodMeals: Int` ve `newFoodsTried: Int` (yeni alanlar)

- [ ] **Step 1: Write the failing test**

`Baby CareTests/WeeklySummarySolidFoodTests.swift`:

```swift
import Testing
import Foundation
@testable import Baby_Care

struct WeeklySummarySolidFoodTests {

    @Test func countsSolidFoodMealsWithinTheWeek() {
        let baby = Baby(
            name: "Test",
            birthDate: Calendar.current.date(byAdding: .month, value: -9, to: .now)!
        )
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: .now)!
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: .now)!

        let solids = [
            SolidFoodRecord(babyID: baby.id, servedAt: twoDaysAgo,
                            foodIDs: ["carrot"], isFirstTry: true),
            SolidFoodRecord(babyID: baby.id, servedAt: twoDaysAgo,
                            foodIDs: ["apple"], isFirstTry: false),
            SolidFoodRecord(babyID: baby.id, servedAt: tenDaysAgo,
                            foodIDs: ["pear"], isFirstTry: true)
        ]

        let summary = WeeklySummaryCalculator.calculate(
            for: baby, feedings: [], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: solids
        )

        #expect(summary.solidFoodMeals == 2)
        #expect(summary.newFoodsTried == 1)
    }

    @Test func excludesOtherBabiesRecords() {
        let baby = Baby(
            name: "Test",
            birthDate: Calendar.current.date(byAdding: .month, value: -9, to: .now)!
        )
        let solids = [SolidFoodRecord(babyID: UUID(), foodIDs: ["carrot"])]

        let summary = WeeklySummaryCalculator.calculate(
            for: baby, feedings: [], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: solids
        )

        #expect(summary.solidFoodMeals == 0)
    }

    @Test func emptySolidFoodListYieldsZero() {
        let baby = Baby(name: "Test", birthDate: .now)
        let summary = WeeklySummaryCalculator.calculate(
            for: baby, feedings: [], sleeps: [], diapers: [],
            growth: [], vaccinations: [], solidFoods: []
        )
        #expect(summary.solidFoodMeals == 0)
        #expect(summary.newFoodsTried == 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests/WeeklySummarySolidFoodTests" -quiet
```

Beklenen: `calculate` çağrısında `solidFoods` etiketi yok — derleme hatası.

- [ ] **Step 3: `WeeklySummaryCalculator`'ı genişlet**

`WeeklySummary` struct'ına `solidFoodMeals: Int` ve `newFoodsTried: Int` eklenir. `calculate` imzasına `solidFoods: [SolidFoodRecord]` parametresi eklenir (varsayılan değer verilmez — tüm çağrı noktaları güncellenmeli, sessizce boş geçilmemeli).

Mevcut çağrı noktaları: `DashboardView.swift:325` ve `WeeklySummaryView`. Her ikisine `@Query` ile alınan `allSolids` geçirilir.

- [ ] **Step 4: `WeeklySummaryView` ve PDF raporuna ekle**

`WeeklySummaryView`'a ek gıda satırı eklenir (yalnız `baby.stage.isSolidFoodAge` iken).

`PDFReportGenerator`'a iki bölüm eklenir (yalnız ek gıda yaşındaki bebekte):
- Ek gıda özeti: toplam öğün, denenen farklı besin sayısı
- Alerjen durum tablosu: dokuz alerjen ve durumları

- [ ] **Step 5: Dashboard kartı ve ipucu metni**

`DashboardView`'a `solidsIntroCard` eklenir: bebek `.complementary` aşamasına geçtiğinde `emergencyHelpCard`'ın altında görünür, `SolidFoodView`'a yönlendirir. Kapatma durumu bebek başına saklanır:

```swift
    @AppStorage private var solidsCardDismissed: Bool
    // init içinde: _solidsCardDismissed = AppStorage(wrappedValue: false,
    //     "solidsIntroCardDismissed_\(baby.id.uuidString)")
```

`weeklyTip(forAgeWeeks:)` fonksiyonunun `default` dalı 24 aya kadar genişletilir: 26–35, 35–52, 52–78, 78+ hafta için ayrı ipuçları.

`SettingsView`'daki "Sürüm" satırı ve "Kaynaklar & Referanslar" bölümüne TÜBER 2022 ile ESPGHAN linkleri eklenir.

- [ ] **Step 6: App Store metinlerini güncelle**

`docs/APP_STORE_TR.md`: altyazı "0–6 ay yenidoğan takibi" → "0–2 yaş bebek bakım takibi"; açıklamada "0–6 ay" geçen yerler güncellenir; ek gıda, besin kütüphanesi ve alerjen takibi için yeni bölüm eklenir; anahtar kelimelere "ek gıda", "tamamlayıcı beslenme", "alerjen" eklenir. `docs/APP_STORE_EN.md` aynı şekilde.

`docs/APP_STORE_REVIEW_NOTES.md`: tıbbi içerik kapsamının genişlediği, tüm içeriğin resmi kaynaklara dayandığı ve uygulamanın tanı/doz/protokol sunmadığı not edilir.

- [ ] **Step 7: Tüm test paketini çalıştır**

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:"Baby CareTests" -quiet
```

Beklenen: tüm testler PASS.

- [ ] **Step 8: Commit**

```bash
git add "Baby Care/Core/Services/WeeklySummaryCalculator.swift" \
        "Baby Care/Core/Services/PDFReportGenerator.swift" \
        "Baby Care/Features" "docs/APP_STORE_TR.md" \
        "docs/APP_STORE_EN.md" "docs/APP_STORE_REVIEW_NOTES.md" \
        "Baby CareTests/WeeklySummarySolidFoodTests.swift"
git commit -m "feat: ek gıda haftalık özete, PDF rapora ve konumlandırmaya işlendi

Haftalık özette ek gıda öğünü ve yeni denenen besin sayısı, PDF
raporda alerjen durum tablosu. Ana sayfada 6. ayda ek gıda kartı.
App Store metinleri 0-24 aya güncellendi.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Self-Review Notları

**Spec kapsamı:** Spec'in 14 bölümü tarandı. Bölüm 3'teki dört hata Task 2–5'te; bölüm 5 veri modeli Task 9'da; bölüm 6 katalogları Task 2, 3, 6, 7, 8, 13'te; bölüm 7 navigasyonu Task 11, 12, 15'te; bölüm 8 yaş kapıları Task 1'de; bölüm 9 güvenlik sınırı Global Constraints ve Task 12–13'te; bölüm 10 entegrasyon noktaları Task 9, 14, 15'te; bölüm 11 test stratejisi ilgili görevlerin test adımlarında karşılandı.

**Bilinçli sapma:** Spec bölüm 6.1 "yaklaşık 130 besin" diyor; Task 8 testleri en az 60 besin arıyor. Spec bölüm 13'teki risk azaltma kararı bu: kütüphane çekirdek besinlerle çıkar, kalanı model ve UI değişmeden ikinci turda eklenir.

**Spec'ten sapan ikinci nokta — Task 13:** Spec bölüm 6.6 "boğulma müdahalesi ve anafilaksi kategorisi eklenir" diyordu. Kod okunduğunda `FirstAidCatalog` içinde `choking` ve `allergy` senaryolarının **zaten var** olduğu ve kaliteli olduğu görüldü. Task 13 buna göre daraltıldı: sıfırdan içerik yazmak yerine üç gerçek boşluk kapatılıyor — öğürme/boğulma ayrımı, 1 yaş üstü karın baskısı ve reçeteli adrenalin. `SymptomCatalog`'daki alerjik reaksiyon kategorisi ise gerçekten yok, o ekleniyor.

**Doğrulanan API adları:** Task 13 ilk yazımında `FirstAidCatalog.topics`, `FirstAidTopic`, `SymptomEntry`, `severity` gibi adlar varsayılmıştı; gerçek adlar `FirstAidCatalog.scenarios`, `FirstAidScenario`, `SymptomScenario`, `urgency`. Plan gerçek adlara göre düzeltildi.

**Sıralama bağımlılıkları:** Task 1 → 5 (BabyStage), Task 7 → 8, 9, 10 (Allergen), Task 8 → 10, 11, 12 (FoodCatalog), Task 9 → 10, 11, 14 (modeller), Task 10 → 11, 12 (servis), Task 11 → 12 (sheet), Task 13 → 11'deki gizli linki açar. Task 2, 3, 4, 6 birbirinden bağımsız; 3 → 4 sırası zorunlu (`isRetired` alanı).
