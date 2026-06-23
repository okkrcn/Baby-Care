# App Review & TestFlight Notları

App Store Connect → uygulama → **App Review Information** bölümüne yapıştırılacak hazır metinler.

## App Review Information → Notes (İngilizce, review ekibi için)

```
This app is a fully offline baby-care tracker for parents of 0–6 month-old babies.

- No account or login is required. There is no demo account needed.
- All data is stored locally on the device (SwiftData). The app does not collect,
  transmit, or share any user data, and contains no analytics, ads, or tracking.
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
