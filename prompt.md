# Baby Care — devam promptu (Cursor için, 2026-09-26)

Bu iOS projesinde (SwiftUI + SwiftData, tamamen offline, ücretsiz, paywall yok) kaldığımız yerden devam et. Önce bu dosyayı ve `docs/superpowers/specs/2026-09-19-ai-asistan-hazirlik.md` dosyasını oku; yeniden keşif yapma.

## Durum
- main = origin/main = `996aeb4` (son kontrol: 2026-09-26). AI model zincirindeki üç yerel değişiklik ve App Store hazırlık dosyaları henüz commit'lenmedi.
- Ek gıda modülü ve isteğe bağlı asistanı içeren 1.6 build 8, App Store Connect'e yüklendi; 26 Eylül 2026 02:04'te Apple incelemesine gönderildi. Son doğrulanan durum: **Waiting for Review**, henüz yayında değil. 1.0 canlı sürüm.
- Testler: 160/160 geçiyor (birim + UI, 2026-09-26). iPhone 17 Pro Max pazarlama ekran testi 1/1 geçti. iPad pazarlama ekran testi iPad sekme çubuğu sorgusu nedeniyle geçmedi; iPad mağaza görselleri mevcut eski sette kaldı.
- AI asistanı: `Baby Care/Core/AI/*` — OpenRouter ücretsiz modeller, varsayılan kapalı, rıza ekranı, anahtar Keychain. Mimari özeti `docs/AI_SETUP.md`.
- `FreeModelCatalog.preferred` 2026-09-22'de canlı `/models` listesine göre yenilendi; metin dışı çıktı veren modeller (`architecture.output_modalities != ["text"]`) zincire alınmıyor.

## 1.7 incelemede (2026-11-16)
- 1.6 yayında (Ready for Distribution). 1.7 (9) main'den arşivlendi, yüklendi ve 2026-11-16 03:0x'te App Review'a gönderildi: **Waiting for Review**, onaydan sonra otomatik yayın.
- App Store Connect: Yenilikler (TR) girildi; inceleme notuna 1.7 test yolu eklendi; şifreleme = "None of the algorithms"; yaş derecelendirmesi yeni anketle yanıtlandı → **13+** (tıbbi bilgi "Infrequent" nedeniyle; önceden 4+).
- Ekran görüntüleri 1.6'dan kaldı (1.7 incelemedeyken sürümde düzenlenemiyor).
- 1.7 görselleri (2026-11-16): `docs/screenshots/v1.7/` (üretim `scripts/build-appstore-v17.mjs`). 3 ekran görüntüsü (kilit ekranı Live Activity, widget + Dynamic Island, diş haritası) ve arama/başlık için universal creative asset (5244×2950) Asset Library'ye yüklendi, ayrı gönderimle incelemeye gönderildi (Waiting for Review). Onaylanınca ürün sayfasına eklenmeleri gerekiyor: ekran görüntüleri sürüme, universal görsel "Header and Search Results"a. Kopya: `~/Desktop/OuzKRCN/08-Reklam_içerikleri/Baby Care - okkrcn.github.io/`.
- main'de 1.7 sonrası (1.7.1'e girer): widget'ta 24 saati geçen süreler gün olarak yazılır; puan isteme tüm kayıt yollarını sayar (didSave gözlemcisi); `babycare://` derin bağlantıları (ana, takip, asi, bebek, ayarlar, dis).

## 1.7.1 (10) yüklendi — 2026-11-16
- main'den arşivlendi ve App Store Connect'e yüklendi (Upload succeeded). İçerik: widget gün biçimi, puan isteme düzeltmesi, `babycare://` derin bağlantıları, `ITSAppUsesNonExemptEncryption = NO`. Testler: 192 birim + 8 UI geçti.
- **Henüz sürüm oluşturulmadı/gönderilmedi**: 1.7 incelemedeyken App Store Connect yeni iOS sürümü açtırmıyor. 1.7 onaylanınca: 1.7.1 sürümünü oluştur, build 10'u seç, Yenilikler metni `docs/APP_STORE_TR.md`'de, sonra uygulama içi etkinliğin tarihlerini 1.7.1 yayınına göre güncelleyip ikisini gönder.

## Büyüme (ücretsiz) adımları — 2026-11-16
- 1.7 tanıtım metni girildi; açıklamaya "KİLİT EKRANI VE WIDGET'LAR" ve "DİŞ GELİŞİMİ" bölümleri, anahtar kelimelere "diş" eklendi (1.7 incelemesiyle birlikte değerlendirilir).
- Öne çıkarma başvurusu (App Enhancements, yayın aralığı 17–24 Kasım) gönderildi: Submitted.
- Uygulama içi etkinlik "Kilit Ekranında Emzirme Sayacı" taslak (Major Update, deep link `babycare://ana`). **Gönderilmedi**: 1.7 build'inde URL şeması yok; 1.7.1 yayına girince tarihleri (şu an 19 Kas–17 Ara) güncelleyip incelemeye gönder.
- Bekleyen: görseller onaylanınca ürün sayfasına bağla; sonra Product Page Optimization ile yeni/eski ekran görüntülerini A/B test et.
- Bilerek yapılmayan: İngilizce mağaza sayfası (uygulama içi yalnız Türkçe, kötü yorum riski), özel ürün sayfaları (dış link/reklam olmadan değeri düşük).
- main'de build 9 sonrası: `ITSAppUsesNonExemptEncryption = NO` eklendi (sonraki build'lerde şifreleme sorusu çıkmaz).

## 1.7 hazırlığı: widget + Live Activity (2026-11-16, `feat/widget-live-activity` dalı, main'e alındı)
- Yeni hedef `Baby Care Widgets`: küçük/orta ana ekran widget'ı, kilit ekranı (dikdörtgen + yuvarlak), emzirme/uyku Live Activity + Dynamic Island. Ortak kod `Shared/`. Mimari notu AGENTS.md "Stack" bölümünde.
- Simülatörde doğrulandı: Dynamic Island kompakt görünüm, kilit ekranı Live Activity, "Uyandı" düğmesinin kaydı bitirip aktiviteyi kapatması, App Group özetinin yazılması.
- Simülatörde ayrıca doğrulandı (2026-11-16): orta widget'ın galeriden eklenmesi, Çiş düğmesi, Emzir düğmesinin arka planda Live Activity açması, widget'taki Bitir düğmesi.
- Doğrulanmadı: küçük/kilit ekranı widget'larının ana ekranda görünümü (galeride küçük widget görüldü), Dynamic Island genişletilmiş görünüm, gerçek cihaz.
- Diş Gelişimi (Bebek → Detaylar): `ToothEruption` modeli, `PrimaryTooth` kataloğu (ADA çıkış tablosu), yedek formatı v3 (`toothEruptions`). Birleştirmede aynı bebeğin aynı dişi tekrar eklenmez. Diş simgesi `Assets.xcassets/ToothIcon` (SF Symbols'da diş yok). Simülatörde haritanın çizimi, diş seçimi, kaydetme ve özet doğrulandı.
- Intent parametreleri düz `String`: AppEnum parametresi widget sürecinden uygulamaya `nil` geçiyordu.
- Sürüm 1.7 (9) yapıldı; App Group ve widget kimliğini otomatik imzalama oluşturdu.

## Bu makinede test
```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5" -parallel-testing-enabled NO
```
`OS=26.5` zorunlu (26.5 ve 27.0'da aynı adlı simülatör var); UI testleri paralel kapalı ister.

## Açık işler (öncelik sırasıyla)
1. **Canlı AI testi.** `docs/AISecrets.example.plist` → `Baby Care/AISecrets.plist` (gitignore'da) içine OpenRouter anahtarı koy, simülatörde Ek Gıda → Asistan'da Türkçe birkaç soru sor. Türkçesi zayıf modeli `preferred`'dan çıkar, sırayı kesinleştir. Kalan risk: `nemotron-3.5-content-safety`, `ling-3.0-flash-fin` gibi amaç dışı modeller metin çıktısı verdiği için dinamik yedek zincirine girebiliyor.
2. **Gizlilik sayfası.** Canlı `https://okkrcn.github.io/Baby-Care/privacy.html` 26 Eylül kontrolünde HTTP 200 dönüyor ve isteğe bağlı asistan bölümünü gösteriyor. App Privacy etiketi artık kullanıcı hesabına bağlanabilen veri olarak beyan edildi; sayfadaki "kimliksiz özet" ifadesi bebek kimliğinin gönderilmemesini anlatır.
3. **App Store Connect:** 1.6 incelemesi bekleniyor; sağlık verisi ve soru metni `Health` + `Other User Content`, App Functionality, linked to user, tracking yok olarak yayımlandı. Türkçe ad, alt başlık, anahtar kelimeler, açıklama ve beş yeni iPhone görseli kaydedildi. Son durum için App Review ekranını yeniden oku; onay sonrası otomatik yayın seçili.
4. Faz 2 içerik: besin kütüphanesini 66 → ~130'a çıkar (yalnız veri, model/UI değişmez).
5. Faz 1 bulut senkronu: `supabase/schema.sql` duruyor; supabase-swift paketi kaldırıldı, gerekince yeniden eklenir.

## Kararlar (değiştirme)
- Tıbbi içerik: tanı yok, doz yok; her ekranda resmi kaynak + "bilgilendirme amaçlıdır".
- Yaş bariyerleri (bal, tuz, inek sütü…) engellemez, uyarır.
- Ek gıda rengi kahverengi; turuncu yalnız uyarı yüzeylerinde.
- Rıza/ayar ekranlarında "OpenRouter" adı bilerek geçiyor: kullanıcı anahtarı oradan alıyor ve rıza metni verinin kime gittiğini söylemek zorunda.
- Bağış yalnız IAP consumable ile olabilir (kural 3.1.1); kapsam dışı bırakıldı.

## Çalışma kuralları
- Commit mesajları Türkçe, mevcut stil (`feat:`, `fix:`, `chore:`, `docs:`).
- "Bitti" demeden test çıktısı göster; test edilmeyeni açıkça yaz.
- `AISecrets.plist` ve anahtarları asla commit'leme, çıktıya basma.
