# Baby Care — Proje AGENTS.md

## Amaç
0–24 ay bebek bakım takibi (beslenme, uyku, bez, aşı, büyüme, ek gıda, alerjen) için ücretsiz, reklamsız, tamamen cihazda çalışan iOS uygulaması. App Store'da yayında; 1.6 sürümü ek gıda AI asistanıyla hazırlanıyor.

## Stack
- SwiftUI + SwiftData (offline, tek veri kaynağı cihaz) · Swift Testing (`Baby CareTests`) + XCUITest (`Baby CareUITests`)
- Dış servis yok; tek istisna isteğe bağlı ek gıda asistanı (`Baby Care/Core/AI/*`, OpenRouter ücretsiz modeller, varsayılan kapalı). Mimari: `docs/AI_SETUP.md`
- `supabase/schema.sql` Faz 1 bulut senkronu için bekliyor; supabase-swift paketi kaldırıldı, gerekince yeniden eklenir

## Komutlar
- Test (birim + UI):
  `xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5" -parallel-testing-enabled NO`
  `OS=26.5` zorunlu (26.5 ve 27.0'da aynı adlı simülatör var); UI testleri paralel kapalı ister
- Mağaza ekran görüntüleri: `scripts/build-appstore-screenshots*.mjs`
- Destek/gizlilik sayfaları `docs/index.html`, `docs/privacy.html` → `gh-pages` dalına elle alınır (yayın = ayrı onay)

## Mevcut faz
1.6 yayın hazırlığı. Açık işler ve durum `prompt.md`'de; hazırlık raporu `docs/superpowers/specs/2026-09-19-ai-asistan-hazirlik.md`. Oturum başında ikisi de okunur, yeniden keşif yapılmaz.

## Değişmez kurallar
1. Ürün ücretsiz kalır: paywall, abonelik, reklam, StoreKit yok (bağış ancak IAP consumable ile olabilir; kapsam dışı).
2. Tıbbi içerik: uygulama tanı koymaz, doz önermez, protokol yürütmez. Her sağlık ekranında resmi kaynak linki + "bilgilendirme amaçlıdır" ibaresi.
3. Alerjen içeriğinde ESPGHAN/AAP konsensüsü esas; TÜBER farkı gizlenmeden not olarak gösterilir.
4. Yaş bariyerleri (bal, tuz, şeker, inek sütü, meyve suyu) engellemez, uyarır — uygulama takip aracıdır, hakem değil.
5. Ek gıda rengi kahverengi; turuncu yalnız semptom/uyarı yüzeylerinde.
6. AI asistanı: üç kapı (rıza + açık + yapılandırılmış) sağlanmadan ağ isteği çıkmaz; bebeğin adı, doğum tarihi, ölçümleri asla gönderilmez. Rıza/ayar ekranlarında "OpenRouter" adı bilerek geçer (kullanıcı anahtarı oradan alır, rıza metni alıcıyı söylemek zorunda) — diğer yüzeylerde sağlayıcı adı geçmez.
7. `Baby Care/AISecrets.plist` ve anahtarlar commit'lenmez, çıktıya basılmaz (`.gitignore`'da).
8. Yedek formatı geriye uyumlu kalır (v2 → v1 okunur); alan eklerken `BackupCompatibilityTests` güncellenir.
9. Kullanıcıya görünen metin Türkçe; commit mesajları Türkçe, `feat:` / `fix:` / `chore:` / `docs:` öneki.
10. "Bitti" demeden test çıktısı gösterilir; test edilmeyen açıkça yazılır.
