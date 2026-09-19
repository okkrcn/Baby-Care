# Yapay Zeka Asistanı — OpenRouter Kurulumu

Ek Gıda ekranındaki asistan, OpenRouter'ın **ücretsiz** (`:free`) modelleriyle çalışır.
Uygulamanın gelir hedefi yoktur; ücretli model, abonelik veya satın alma içermez.

## Mimari (özet)

```
SolidFoodAssistantView  ──►  AIAssistantStore  ──►  OpenRouterClient  ──►  openrouter.ai/api/v1
        │                         │                       ▲
        │  rıza + ayarlar         │  AIConfiguration       │  (veya vekil: proxy/openrouter-worker.js)
        ▼                         ▼                       │
   AIConsentView            AIKeyStore (Keychain)   FreeModelCatalog (ücretsiz model zinciri)
        │
   SolidFoodAssistant  →  AssistantContext (kimliksiz özet) + sistem istemi (güvenlik kuralları)
```

| Dosya | Görev |
|---|---|
| `Core/AI/AIConfiguration.swift` | Anahtar/adres çözümü: kullanıcı anahtarı → `AISecrets.plist` → `OPENROUTER_API_KEY` ortam değişkeni (yalnız Debug) |
| `Core/AI/AIKeyStore.swift` | Kullanıcının kendi anahtarını Keychain'de tutar (bu cihaz, iCloud'a gitmez) |
| `Core/AI/OpenRouterClient.swift` | `chat/completions` ve `models` çağrıları, hata eşlemesi, model fallback zinciri |
| `Core/AI/FreeModelCatalog.swift` | Tercih edilen ücretsiz modeller + `/models` listesinden dinamik seçim |
| `Core/AI/SolidFoodAssistant.swift` | Kimliksiz bağlam (`AssistantContext`), sistem istemi, örnek sorular |
| `Core/AI/AIAssistantStore.swift` | Açık/kapalı, rıza, model zinciri yenileme (`@Observable`) |
| `Features/SolidFood/SolidFoodAssistantView.swift` | Rıza ekranı + sohbet arayüzü |
| `Features/Household/AIAssistantSettingsView.swift` | Ayarlar → Yapay Zeka Asistanı |

## Üç kapı

Asistan yalnız üç koşul birlikte sağlanınca istek gönderir:

1. **Rıza:** İlk açılışta `AIConsentView` ne gönderildiğini listeler; kabul edilmeden ağ isteği çıkmaz.
2. **Açık:** Ayarlar'daki anahtar (`AIAssistantStore.isEnabled`) — rıza geri alınınca kapanır.
3. **Yapılandırılmış:** Bir anahtar ya da vekil adresi var (`AIConfiguration.isConfigured`).

## Anahtar nereden gelir?

Öncelik sırasıyla:

| Kaynak | Ne zaman | Nasıl |
|---|---|---|
| Kullanıcının kendi anahtarı | Her sürümde çalışır | Ayarlar → Yapay Zeka Asistanı → anahtar gir. Keychain'de tutulur. |
| `AISecrets.plist` (pakette) | Geliştirme, TestFlight | Aşağıda. |
| `OPENROUTER_API_KEY` ortam değişkeni | Yalnız Debug | Xcode → Scheme → Run → Arguments → Environment Variables |

### Geliştirme: `AISecrets.plist`

1. `docs/AISecrets.example.plist` dosyasını `Baby Care/AISecrets.plist` olarak kopyalayın
   (klasör Xcode'da senkronize grup olduğu için dosya otomatik pakete girer; `.gitignore`'da).
2. [openrouter.ai/keys](https://openrouter.ai/keys) adresinden anahtar alın — ücretsiz modeller için bakiye gerekmez.
3. `OPENROUTER_API_KEY` alanına yapıştırın, `OPENROUTER_BASE_URL` boş kalsın.

### Mağaza sürümü: vekil (önerilen)

Pakete gömülen anahtar cihazdan çıkarılabilir. Yayında anahtarı bir vekilde tutun:

1. `proxy/openrouter-worker.js` dosyasını Cloudflare Workers'a yükleyin (ücretsiz plan yeterli):
   ```bash
   npm i -g wrangler && wrangler login
   wrangler secret put OPENROUTER_API_KEY --name baby-care-ai
   wrangler deploy proxy/openrouter-worker.js --name baby-care-ai
   ```
2. `AISecrets.plist` içinde `OPENROUTER_API_KEY` satırını **silin**, `OPENROUTER_BASE_URL` alanına
   `https://baby-care-ai.<hesap>.workers.dev/api/v1` yazın.
3. Uygulama bu durumda "vekil modu"na geçer: cihazda anahtar yoktur, `Authorization` başlığı gönderilmez.

Vekil yalnız iki uç noktaya izin verir, yalnız `:free` modelleri geçirir, gövdeyi 64 KB ve
`max_tokens`'ı 1024 ile sınırlar, IP başına dakikada 20 istek uygular.

## Ücretsiz model seçimi

`FreeModelCatalog.preferred` sıralı aday listesidir; ilk model asıl, kalanlar yedek olarak
tek istekte `models` alanıyla gönderilir. OpenRouter kotası dolan modeli atlayıp sıradakine geçer.

Uygulama günde bir kez `/models` listesini çekip o an gerçekten ücretsiz olanları süzer
(`pricing.prompt == 0 && pricing.completion == 0`, bağlam ≥ 8k). Ücretsiz modeller sık
değiştiği için sabit listeye güvenilmez; liste çekilemezse tercih listesi olduğu gibi kullanılır.

Tercih listesini güncellemek için `FreeModelCatalog.preferred` dizisini düzenleyin;
güncel liste: <https://openrouter.ai/models?q=free>.

## Gizlilik sınırı

`AssistantContext` yapısında **ad, doğum tarihi, fotoğraf, ölçüm** alanı yoktur; test
(`SolidFoodAssistantTests.systemPromptNeverContainsIdentity`) alan eklenirse kırılır.
Gönderilen: ay cinsinden yaş, denenen besinler, alerjen durumları, soru metni, aynı sohbetin
son 10 mesajı. Gizlilik politikasının "Yapay Zeka Asistanı" bölümü bu listeyi tarif eder;
alan eklerken orayı ve `AIConsentView`'i de güncelleyin.

## Tıbbi sınır

Sistem istemi uygulamanın geri kalanıyla aynı çizgidedir: tanı yok, doz yok, alerji protokolü
yok; acil belirtide 112; öneriler yalnız `FoodCatalog`'daki yaşa uygun besinlerden; yaş
bariyerli besinler (bal, tuz, şeker, inek sütü) ve tepki gözlenen alerjenler önerilmez.
Her yanıtın üstünde sorumluluk ibaresi görünür.

## Test

- `AIConfigurationTests` — anahtar önceliği, vekil modu, plist ayrıştırma
- `FreeModelCatalogTests` — ücretsiz süzme, sıralama, üst sınır
- `OpenRouterClientTests` — istek başlıkları/gövdesi, hata eşlemesi (sahte aktarım, ağ yok)
- `SolidFoodAssistantTests` — bağlam üretimi, sistem istemi, kimlik sızıntısı koruması

Ağa çıkan test yoktur; gerçek OpenRouter çağrısı yalnız cihazda elle denenir.
