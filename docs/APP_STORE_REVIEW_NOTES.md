# App Review & TestFlight Notları

App Store Connect → uygulama → **App Review Information** bölümüne yapıştırılacak hazır metinler.

## App Review Information → Notes (İngilizce, review ekibi için)

```
This app is a local-first baby-care tracker for parents of 0–24 month-old babies.

- No account or login is required. There is no demo account needed.
- All data is stored locally on the device (SwiftData). The app does not collect,
  transmit, or share any user data, and contains no analytics, ads, or tracking.
- Optional AI assistant (Solid Food → Assistant tab, off by default): after an
  explicit in-app consent screen, the user's typed question plus a de-identified
  summary (baby age in months, foods tried, allergen statuses) is sent to the
  OpenRouter API to get a text answer from free open models. No name, birth date,
  photo, measurements or identifiers are sent. The feature can be disabled and
  consent withdrawn in Settings → AI Assistant. Answers carry a medical disclaimer.
  To test: Settings → AI Assistant → enter an OpenRouter key (free tier is enough),
  then open a baby aged 6+ months → Solid Food → Assistant.
- The app shows informational health content (vaccination schedule based on the
  Turkish MoH 2026 immunization program, WHO growth percentiles, first-aid and
  symptom guidance). A medical disclaimer is shown in-app and in the listing:
  the content is informational and does not replace professional medical advice.
- On first launch the onboarding lets the reviewer create a baby profile; all
  screens (tracking, vaccination, growth, PDF export) become populated afterward.
- Notifications are used only for local reminders (vaccinations, weekly growth
  measurement, medication, milk storage expiry).
```

## Encryption / Export Compliance

- Soru: "Does your app use encryption?" → **No** (yalnızca OS'un standart HTTPS/şifrelemesini
  kullanır, özel/non-exempt şifreleme yok). Bu sayede yüklemede ek belge istenmez.
- (Kalıcı çözüm) Xcode'da bu soruyu tamamen kaldırmak için:
  **Target "Baby Care" → Build Settings → arama: "encryption" →
  "App Uses Non-Exempt Encryption" = NO** (build setting: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`).

## Age Rating

- 4+ hedefle. Anket: tümü "None"; "Medical/Treatment Information" → **Infrequent/Mild**.

## App Privacy (Nutrition Label)

- "Data Collection" → **We do not collect data from this app.** (Hiçbir kutu işaretlenmez.)

## Privacy Policy URL

- Apple canlı bir URL ister. `docs/PRIVACY_POLICY_TR.md` (veya EN) içeriğini bir public
  GitHub Gist veya GitHub Pages'e koyup URL'i App Information → Privacy Policy URL'e yapıştır.

## Support URL

- E-posta tabanlı destek sayfası ya da basit bir GitHub Pages yeterli.

## Sürüm 1.5 — Ek Gıda Modülü (kapsam genişlemesi)

Uygulamanın yaş kapsamı 0–6 aydan 0–24 aya genişletildi ve tamamlayıcı
beslenme (ek gıda) takibi eklendi.

**Tıbbi içerik sınırı — değişmedi:** Uygulama tanı koymaz, ilaç veya doz
önermez, alerji protokolü yürütmez. Yeni eklenen her ekranda (a) tıklanabilir
resmi kaynak linki ve (b) "Bu içerik bilgilendirme amaçlıdır; hekim önerisinin
yerini tutmaz" ibaresi bulunur.

**Yeni içeriğin kaynakları:**
- Tamamlayıcı beslenme önerileri: T.C. Sağlık Bakanlığı Türkiye Beslenme
  Rehberi (TÜBER 2022) ve DSÖ 2023 tamamlayıcı beslenme kılavuzu
- Alerjen tanıtımı: ESPGHAN, AAP 2023 klinik raporu, EAACI 2021, NIAID
- Aşı takvimi: Ulusal Çocukluk Dönemi Aşılama Takvimi (2025)
- Büyüme eğrileri: WHO Child Growth Standards, ay bazlı persentil tabloları
- Gelişim mihenk taşları: CDC "Learn the Signs. Act Early." (2022 revizyonu)
- Boğulma ve anafilaksi: AAP Allergy and Anaphylaxis Emergency Plan

**Yaş bariyerleri engelleyici değildir:** Bal, tuz, ilave şeker gibi besinler
için yaş uyarısı gösterilir, ancak kullanıcının kayıt tutması engellenmez.
Uygulama bir takip aracıdır; beslenme kararı ebeveyn ve hekimindir.

**Acil durum yönlendirmesi:** Anafilaksi ve boğulma ekranları kullanıcıyı
112'ye yönlendirir. Uygulama içinden arama başlatılmaz; yalnızca bilgi verilir.


## Sürüm 1.6 — Yapay Zeka Asistanı (isteğe bağlı)

- **Varsayılan kapalı**; ilk kullanımda rıza ekranı. Rıza olmadan ağ isteği çıkmaz.
- Yalnız OpenRouter'ın ücretsiz modelleri kullanılır; uygulama içi satın alma yoktur.
- Gönderilen veri kimliksizdir (ay cinsinden yaş, denenen besinler, alerjen durumları, soru metni).
- **App Privacy etiketi güncellenmeli:** asistan açıkken "Other User Content"
  (soru metni) ve "Health & Fitness → Other Health Data" (kimliksiz beslenme özeti)
  kategorileri "Data Not Linked to You / App Functionality" olarak işaretlenir.
  Asistan kapalıyken hiçbir veri gönderilmediği için not alanında bunun isteğe
  bağlı olduğu belirtilir.
- Yanıtlar bilgilendirme amaçlıdır; her ekranda sorumluluk ibaresi ve 112 uyarısı var.
- Uygulama tarafı ayrıntıları: `docs/AI_SETUP.md`.
