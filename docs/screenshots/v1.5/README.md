# Sürüm 1.5 — Ekran Görüntüleri

Ek gıda modülüyle birlikte 0–24 ay kapsamına geçen sürümün görselleri.

## Ham ekran görüntüleri (bu klasör)

iPhone 17 Pro Max, iOS 26.5 · 1320×2868 (App Store 6.9" formatı)

`Baby CareUITests/MarketingScreenshotTests.swift` ile üretildi. Yeniden çekmek için:

```bash
xcodebuild test -project "Baby Care.xcodeproj" -scheme "Baby Care" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5' \
  -only-testing:"Baby CareUITests/MarketingScreenshotTests" \
  -parallel-testing-enabled NO -resultBundlePath /tmp/shots.xcresult
xcrun xcresulttool export attachments --path /tmp/shots.xcresult --output-path /tmp/shots
```

Ön koşul: simülatörde 6 ayını doldurmuş, kayıt dolu bir bebek profili bulunmalı.
`-parallel-testing-enabled NO` zorunlu — klon simülatörde kullanıcı verisi olmaz.

**App Store'a bu klasördeki ham görüntüler yüklenmelidir.** Metinler gerçek pikseldir.

## Mockup'lar (`mockups/`)

Higgsfield GPT Image 2 ile üretildi; ham görüntü referans olarak verilip telefon
bir sahnenin içine yerleştirildi. Her ekranın kendi sahnesi var, hepsi aynı ışık
ve palet ailesinde.

**Sosyal medya, web sitesi ve tanıtım içindir.** Ekran içeriği model tarafından
yeniden çizildiği için metinlerde kayma olabilir — `01-ana-sayfa.png` içinde
"Belirti kontrolü" yerine "Belirli kontrolü" yazıyor. App Store'a yüklemeden önce
her görseli okuyun.

## Bilinen eksik

`02-takip.png` içindeki Ek Gıda kartı "0 öğün" gösteriyor. Öğün kaydı eklemek için
simülatörde elle birkaç öğün girilmeli, sonra görüntü yeniden çekilmeli.
