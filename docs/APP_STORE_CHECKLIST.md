# App Store Yayın Kontrol Listesi

## 0. Apple Developer Hesabı

- [ ] Apple Developer Program üyeliği aktif ($99/yıl)
- [ ] App Store Connect erişimi var

## 1. Hazırlanan Dosyalar (Bu repodadır)

- [x] **Privacy Policy** — `docs/PRIVACY_POLICY_TR.md` + `docs/PRIVACY_POLICY_EN.md`
- [x] **App Store Listing TR** — `docs/APP_STORE_TR.md`
- [x] **App Store Listing EN** — `docs/APP_STORE_EN.md`
- [x] **App Icon** — Assets.xcassets içinde (light + dark + tinted varyantları)

## 2. Privacy Policy'yi Yayınlama

Apple App Store Connect, Privacy Policy için **canlı bir URL** ister. İki seçenek:

### Seçenek A — GitHub Gist (en hızlı, ücretsiz)
1. https://gist.github.com → New gist
2. Dosya adı: `baby-care-privacy.md`
3. İçeriği `PRIVACY_POLICY_TR.md` veya `PRIVACY_POLICY_EN.md` (veya ikisini birleştir)
4. Create public gist
5. Açılan URL'i kopyala (Raw butonu üzerine sağ tık → URL kopyala daha güzel)

### Seçenek B — Bu deponun GitHub Pages'i
`gh-pages` dalı. `okkaracan.github.io` hesabı yok; o adres 404 verir.
- Destek: `https://okkrcn.github.io/Baby-Care/`
- Gizlilik: `https://okkrcn.github.io/Baby-Care/privacy.html`

## 3. Xcode Tarafında Yapılacaklar

### 3.1 Bundle Identifier ve Sürüm
- Target → Baby Care → General sekmesi
- **Bundle Identifier**: `okkrcn.Baby-Care` (mevcut, OK)
- **Version**: `1.0`
- **Build**: `1` (her arşivde 1 artırılır)

### 3.2 Display Name
- Target → General → **Display Name**: `Baby Care`
- (Info.plist'te `CFBundleDisplayName`)

### 3.3 Signing & Capabilities
- **Team**: Apple Developer hesabınızı seçin
- **Signing Certificate**: Apple Distribution

### 3.4 Deployment Target
- iOS 26.5 (mevcut, OK)
- macOS 26.5 dahil — eğer App Store'a yalnızca iOS gönderilecekse macOS desteğini kaldırmak isteyebilirsiniz (Mac Catalyst dahil olabilir; opsiyonel)

## 4. App Store Connect'te Yapılacaklar

### 4.1 Yeni Uygulama Oluşturma
1. App Store Connect → My Apps → "+" → New App
2. Platform: **iOS** (iPadOS otomatik dahil)
3. Name: `Baby Care: Bebek Bakım Rehberi`
4. Primary Language: **Turkish**
5. Bundle ID: `okkrcn.Baby-Care`
6. SKU: `baby-care-001` (kendi seçeceğin benzersiz kod)
7. User Access: Full Access

### 4.2 App Information Sayfası
- **Subtitle (TR)**: docs/APP_STORE_TR.md'den
- **Category**: Health & Fitness
- **Content Rights**: "Does this app contain third-party content?" → No
- **Age Rating**: 4+ (anketi doldur, hepsi "None"; "Medical/Treatment Information" için **Infrequent/Mild**)

### 4.3 Pricing and Availability
- **Price**: Free
- **Availability**: Türkiye + tüm ülkeler (istediğin gibi)

### 4.4 App Privacy
- **Data Collection**: "We do not collect data from this app" → ✅
- (Hiçbir veri toplama kutusunu işaretleme, hepsi boş kalsın)

### 4.5 Version 1.0 Sayfası
- **Promotional Text**: docs/APP_STORE_TR.md'den
- **Description**: docs/APP_STORE_TR.md'den
- **Keywords**: docs/APP_STORE_TR.md'den
- **What's New in This Version**: docs/APP_STORE_TR.md'den
- **Support URL**: e-posta veya GitHub Pages
- **Marketing URL**: opsiyonel
- **Privacy Policy URL**: yukarıdaki Gist/Pages URL

### 4.6 Screenshots (Zorunlu)

iOS App Store en az **iPhone 6.5" veya 6.7" boyutlarında** 3 ekran görüntüsü ister. Önerilen 5-8 ekran:

1. Ana ekran (Dashboard) — bebek bilgisi + sıradaki aşı kartı
2. Takip ekranı (canlı sayaç + günün özeti)
3. Aşı takvimi (yaklaşan + tamamlanan)
4. Büyüme grafiği (DSÖ persentil)
5. Gelişim rehberi
6. (opsiyonel) Vitamin & ilaç ekranı
7. (opsiyonel) PDF rapor önizleme
8. (opsiyonel) Ayarlar (gizlilik vurgusu)

**Nasıl çekilir**: Xcode → Simulator → iPhone 16 Pro Max'i seç → ⌘+S ekran görüntüsü.

iPad ekran görüntüleri opsiyonel (ama iPad uyumluysa eklemek profesyonel görünüm sağlar).

### 4.7 Yerelleştirme (opsiyonel)
- English (US) eklemek istersen: + Add Language → docs/APP_STORE_EN.md içeriği

## 5. Test (TestFlight)

Submit etmeden önce:
1. Xcode → Product → **Archive**
2. Organizer → Distribute App → App Store Connect → Upload
3. Build işlendikten sonra (~10 dk) App Store Connect → TestFlight
4. Internal Testers eklenip (sen + birkaç ebeveyn) en az **3 gün gerçek cihazda test**

## 6. Submit for Review

1. Version 1.0 sayfasında "Add for Review"
2. Apple'ın gözden geçirme süresi: ortalama **24-48 saat** (bazen 7 güne kadar)
3. Onaylanırsa: "Ready for Sale" → otomatik olarak App Store'da yayında

## 7. Yayın Sonrası

- [ ] App Store linkini sosyal medya / forumlarda paylaş
- [ ] Kullanıcı geri bildirimlerini izle (e-posta + App Store yorumları)
- [ ] Crash raporlarını Xcode Organizer'dan kontrol et
- [ ] Çakışma/hata varsa hızlı 1.0.1 yayını

## Olası Reddedilme Sebepleri (Apple Review)

1. **Sağlık ve tıbbi bilgi içeren uygulamalar daha sıkı kontrol edilir.** Tıbbi sorumluluk reddi açıkça uygulamada **ve** App Store description'da olmalı — bu yapıldı ✅
2. **Privacy Policy URL erişilebilir olmalı.** Gist veya Pages'in canlı olduğunu kontrol et.
3. **Demo veri** — App Review için "demo" bebek profili açmak gerekmez (uygulama onboarding'siz çalışır mı? bebek girilmeden bazı ekranlar boş gösterilir — bu tasarımdır).
4. **Kullanım açıklaması metinleri** — bildirim izin metni özelleştirilmiş mi? `NSUserNotificationUsageDescription` Info.plist'e gerekirse eklenebilir (modern UNUserNotificationCenter için **gerekli değil**, ama review için bilgilendirici).

## Notlar

- **Reklam yok, satın alma yok** → "App Sandbox" + "User Tracking" tamamen kapalı, bu da review'i hızlandırır.
- **Tek dil (TR) ile başla, sonradan EN ekle** — review yükünü azaltır.
- Apple, "Baby" ve "Care" gibi yaygın terimleri içeren uygulama isimlerinde marka karışıklığı varsa uyarabilir. Marka araması yapmak iyi olur: https://www.turkpatent.gov.tr/
