# İkinci Güncelleme Hazırlık Raporu — Ek Gıda + Yapay Zeka Asistanı

**Tarih:** 2026-09-19
**Kapsam:** 1.5 ek gıda modülünün durumu, ikinci güncellemeye (1.6) hazırlık, OpenRouter altyapısı

## 1. Ek gıda modülü (1.5) — durum

Tasarım dokümanındaki (2026-09-08) Faz 1 kapsamı **tamamen uygulanmış**:

| Alan | Durum |
|---|---|
| `BabyStage` yaş kapısı, 0–24 ay genişletmesi | ✅ |
| WHO persentil 7–24 ay, clamp hatası (H-1) | ✅ |
| Aşı takvimi 24 ay, KPA şeması, `kpa_6m` temizliği (H-2/H-3) | ✅ |
| Yaşa duyarlı beslenme hesabı (H-4) | ✅ |
| Gelişim rehberi 6–24 ay (5 aşama) | ✅ |
| 9 major alerjen kataloğu + `AllergenIntroduction` | ✅ |
| Besin kütüphanesi | ✅ 66 besin (hedef ~130; tasarımda ilk tur ~60 kabul edilmişti) |
| `SolidFoodRecord`, servis, takip kartı, öğün formu | ✅ |
| Yedek v2 (geriye uyumlu), PDF, haftalık özet | ✅ |
| Boğulma / anafilaksi güvenlik içeriği | ✅ |
| Testler (katalog, servis, yedek uyumluluğu, UI ekran görüntüsü) | ✅ |

## 2. Bulunan eksikler ve bu güncellemede yapılanlar

| # | Eksik | Aksiyon |
|---|---|---|
| E-1 | **OpenRouter / yapay zeka altyapısı hiç yoktu** — projede tek bir ağ çağrısı bile yoktu. | Kuruldu: `Core/AI/*`, asistan sekmesi, ayarlar, rıza, vekil örneği, testler. Bkz. `docs/AI_SETUP.md`. |
| E-2 | Ayarlar → "Tüm Verileri Sıfırla" `SolidFoodRecord`, `AllergenIntroduction` ve `BreastMilkBatch` kayıtlarını silmiyordu (veri kalıyordu). | Düzeltildi. |
| E-3 | Ayarlar'da sürüm "1.0 (Faz 3)" sabit yazıyordu. | Info.plist'ten okunur oldu. |
| E-4 | Gizlilik politikası "0–6 ay" ve "hiçbir dış servis yok" diyordu; asistanla çelişirdi. | TR/EN politikalar güncellendi (isteğe bağlı asistan bölümü). |
| E-5 | `docs/SETUP.md` kaldırılmış Supabase kurulumunu anlatıyordu. | Rehber silindi (2026-09-21); `supabase/schema.sql` Faz 1 bulut planı için tutuldu. |
| E-6 | App Review notları 0–6 ay diyordu; AI için açıklama yoktu. | Güncellendi; App Privacy etiketi uyarısı eklendi. |

## 3. Yayın öncesi hâlâ yapılması gerekenler (kod dışı)

- [x] Xcode: `MARKETING_VERSION` 1.6, `CURRENT_PROJECT_VERSION` 8 (2026-09-22).
- [ ] `Baby Care/AISecrets.plist` oluştur (geliştirme) **veya** vekili yayınlayıp `OPENROUTER_BASE_URL` gir (mağaza).
- [ ] App Store Connect → App Privacy: asistan için "Other User Content" + "Other Health Data", *Not linked to you / App functionality*.
- [x] `docs/APP_STORE_TR.md` / `EN.md` "What's New" 1.6 metni eklendi (2026-09-22).
- [ ] Gerçek cihazda ücretsiz model zincirini dene. (`preferred` listesi 2026-09-22'de canlı `/models` listesine göre yenilendi; Türkçe kalitesi henüz denenmedi.)
- [ ] Faz 2 içerik hedefi: besin kütüphanesini ~130'a çıkar (model/UI değişmez, yalnız veri).

## 4. Bağış ("bir kahve ısmarla") notu

App Store kuralı 3.1.1 gereği uygulama içi bağış **yalnız** In-App Purchase (consumable) ile yapılabilir;
dış bağış linki (Buy Me a Coffee vb.) iOS'ta reddedilir. StoreKit 2 ile tek bir consumable ürün
("Kahve ısmarla") tanımlamak yeterli; karşılığında özellik açılmaz. Bu PR'ın kapsamı dışında bırakıldı.
