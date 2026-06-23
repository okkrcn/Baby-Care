# Baby Care — Kurulum Rehberi (Faz 1)

Bu belge, geliştirici makinesinde projeyi ayağa kaldırmak için **bir kere** yapılacak işleri listeler. Tahmini süre: **20–30 dakika**.

---

## 1) Supabase Projesi

### 1.1 Hesap ve proje
1. [supabase.com](https://supabase.com) → Sign up (GitHub ile gir önerilir).
2. **New project** → Name: `baby-care`, region: **Frankfurt (eu-central-1)** (TR'ye yakın). Şifreyi 1Password gibi bir yerde sakla.
3. Proje yüklenince **Settings → API** sekmesinde şu iki değeri kopyala (kuruluma yapıştıracaksın):
   - `Project URL`
   - `anon public key`

### 1.2 Şemayı yükle
1. Sol menüden **SQL Editor** → **New query**.
2. `supabase/schema.sql` dosyasının **tamamını** kopyala-yapıştır → **Run**.
3. Hata almazsan Tables sekmesinde `profiles`, `households`, `household_members`, `household_invites`, `babies` görünmelidir.

### 1.3 Auth ayarları
1. **Authentication → Providers**:
   - **Email**: enabled (default), "Confirm email" → şimdilik **off** bırak (geliştirme kolaylığı; production'da aç).
   - **Apple**: enabled. Services ID, Team ID, Key ID, Private key gerekecek. Bunlar için Apple Developer panelinde Sign In with Apple konfigürasyonu yapacaksın (aşağıda 3. adım).
2. **Authentication → URL Configuration → Site URL**: `babycare://auth-callback`
3. **Redirect URLs**: `babycare://auth-callback` ekle.

---

## 2) Xcode Projesi

### 2.1 Supabase Swift SDK ekle
1. Xcode'da projeyi aç → **File → Add Package Dependencies…**
2. URL: `https://github.com/supabase/supabase-swift`
3. Dependency Rule: **Up to Next Major Version**, başlangıç: en son sürüm (2.x+).
4. Hedef: **Baby Care** target'ına `Supabase` (umbrella) ürününü ekle.

### 2.2 Supabase config'ini koy
1. Proje root'una `Config.local.xcconfig` adında bir dosya oluştur (Xcode'a EKLEME — sadece dosya sisteminde olsun, `.gitignore`'a düş):

   ```xcconfig
   SUPABASE_URL = https:/$()/PROJE-ID.supabase.co
   SUPABASE_ANON_KEY = ey...senin-anon-key...
   ```

   > Not: `https://` içindeki `//` xcconfig'te yorum gibi parse edilir. `$()` araya koymak Apple'ın resmi önerisidir (KAYNAK: Apple Tech Q&A QA1881 mantığı). Build sırasında düz `https://...` olur.

2. Bu değerler `Info.plist`'e otomatik yansıtılacak. `Info.plist`'e şu iki anahtar eklenecek (kod tarafında halledilecek):
   - `SUPABASE_URL` → `$(SUPABASE_URL)`
   - `SUPABASE_ANON_KEY` → `$(SUPABASE_ANON_KEY)`

3. **Target → Build Settings → Configurations**: hem Debug hem Release için `Config.local.xcconfig`'i ata.

### 2.3 .gitignore
Proje root'undaki `.gitignore` dosyasına ekle:
```
Config.local.xcconfig
*.xcuserstate
xcuserdata/
.DS_Store
```

---

## 3) Apple Developer — Sign In with Apple

> Bu adım sadece geliştirici hesabıyla yapılabilir. Atlanırsa Apple ile giriş çalışmaz; email/şifre çalışmaya devam eder.

### 3.1 Capability ekle
1. Xcode → Target **Baby Care** → **Signing & Capabilities** → **+ Capability** → **Sign in with Apple**.
2. Aynı sayfada Bundle ID'ni not al (örn: `com.ouzkrcn.babycare`).

### 3.2 URL Scheme (deep link callback)
1. **Info** sekmesi → **URL Types** → `+`:
   - **Identifier**: `com.ouzkrcn.babycare`
   - **URL Schemes**: `babycare`
   - **Role**: Editor

### 3.3 Apple Developer Portal
1. [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**.
2. **Identifiers** → Bundle ID'ni bul → **Sign In with Apple** capability'sini etkinleştir.
3. **Services IDs** → yeni Services ID oluştur (örn: `com.ouzkrcn.babycare.web`):
   - **Sign In with Apple** seçeneğini aç.
   - **Configure** → Primary App ID: Bundle ID'n. **Domains**: `PROJE-ID.supabase.co`. **Return URLs**: `https://PROJE-ID.supabase.co/auth/v1/callback`.
4. **Keys** → yeni Key oluştur → **Sign In with Apple**. Private key `.p8` dosyasını indir (bir daha indirilemez!).
5. Supabase → **Authentication → Providers → Apple**:
   - **Services ID** = oluşturduğun Services ID
   - **Team ID** = Apple Developer hesabındaki Team ID
   - **Key ID** = oluşturduğun Key'in ID'si
   - **Private Key** = `.p8` dosyasının içeriği

---

## 4) Cihaz Üzerinde Test

1. Xcode → Run (`⌘R`) → simülatör veya gerçek cihaz.
2. İlk açılışta giriş ekranı gelir → email ile kayıt ol.
3. Onboarding → **Household oluştur** → bebek profili gir.
4. İkinci cihazda (veya simülatörde) farklı email ile kayıt ol → **Davet kodu ile katıl** → 1. cihazdaki owner'dan davet kodunu al.

---

## 5) Sorun Giderme

| Sorun | Olası Sebep | Çözüm |
|---|---|---|
| Build error: `SUPABASE_URL is nil` | Config.local.xcconfig atanmamış veya bulunamadı | Target Build Settings → Configurations'tan ata |
| Apple sign-in "Cannot complete" | Services ID yanlış veya domain doğrulanmamış | Apple Developer panelindeki Services ID'ye dön, domains kısmını kontrol et |
| RLS error: "permission denied" | Auth header oturum açmamış | Sign in oldun mu kontrol et, `auth.uid()` null olmamalı |
| Realtime callback gelmiyor | Tablo realtime publication'da değil | `schema.sql` sonundaki `alter publication` komutları çalıştı mı? |

---

## 6) Sıradaki Faz Hatırlatması (referans)

- **Faz 2:** Besleme + Uyku + Bez takip ekranları + lokal CRUD + sync
- **Faz 3:** Aşı takvimi + UserNotifications bildirimleri
