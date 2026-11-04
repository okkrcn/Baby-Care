# Baby Care — devam promptu (Cursor için, 2026-09-26)

Bu iOS projesinde (SwiftUI + SwiftData, tamamen offline, ücretsiz, paywall yok) kaldığımız yerden devam et. Önce bu dosyayı ve `docs/superpowers/specs/2026-09-19-ai-asistan-hazirlik.md` dosyasını oku; yeniden keşif yapma.

## Durum
- main = origin/main = `996aeb4` (son kontrol: 2026-09-26). AI model zincirindeki üç yerel değişiklik ve App Store hazırlık dosyaları henüz commit'lenmedi.
- Ek gıda modülü ve isteğe bağlı asistanı içeren 1.6 build 8, App Store Connect'e yüklendi; 26 Eylül 2026 02:04'te Apple incelemesine gönderildi. Son doğrulanan durum: **Waiting for Review**, henüz yayında değil. 1.0 canlı sürüm.
- Testler: 160/160 geçiyor (birim + UI, 2026-09-26). iPhone 17 Pro Max pazarlama ekran testi 1/1 geçti. iPad pazarlama ekran testi iPad sekme çubuğu sorgusu nedeniyle geçmedi; iPad mağaza görselleri mevcut eski sette kaldı.
- AI asistanı: `Baby Care/Core/AI/*` — OpenRouter ücretsiz modeller, varsayılan kapalı, rıza ekranı, anahtar Keychain. Mimari özeti `docs/AI_SETUP.md`.
- `FreeModelCatalog.preferred` 2026-09-22'de canlı `/models` listesine göre yenilendi; metin dışı çıktı veren modeller (`architecture.output_modalities != ["text"]`) zincire alınmıyor.

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
