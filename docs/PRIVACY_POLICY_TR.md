# Gizlilik Politikası — Baby Care

**Son güncelleme:** 19 Eylül 2026

## Özet

Baby Care, sizin ve bebeğiniz hakkındaki **hiçbir veriyi toplamaz, paylaşmaz veya internete göndermez**. Tüm bilgiler yalnızca cihazınızda saklanır.

Tek istisna, **isteğe bağlı ve varsayılan olarak kapalı** olan Yapay Zeka Asistanı'dır. Onu açarsanız, yalnız siz soru sorduğunuzda ve yalnız aşağıda "Yapay Zeka Asistanı" bölümünde listelenen kimliksiz bilgiler OpenRouter'a gönderilir.

## Toplanan Veriler

Hiçbir kişisel veri toplanmaz. Uygulama herhangi bir sunucuya veri göndermez, analitik servisi kullanmaz, reklam ağına bağlanmaz ve üçüncü taraflarla bilgi paylaşmaz.

## Cihazda Saklanan Veriler

Uygulamayı kullanırken aşağıdaki bilgileri kendi cihazınıza kaydedersiniz:

- Bebeğin adı, doğum tarihi, cinsiyeti, doğum kilosu/boyu
- Beslenme, uyku, bez takibi kayıtları
- Aşı takvimi ve tamamlanma durumu
- Büyüme ölçümleri (kilo, boy, baş çevresi)
- Vitamin ve ilaç takibi
- Kullanıcı notları

Bu veriler yalnızca cihazınızdaki yerel veritabanında (Apple SwiftData) saklanır. iCloud yedekleme açıksa, sistem yedekleme politikası uyarınca diğer cihaz yedeklerinizle birlikte iCloud'a alınabilir — bu işlem Apple tarafından şifreli olarak gerçekleştirilir ve Baby Care'in kontrolünde değildir.

## Bildirimler

İzin verdiğiniz takdirde uygulama yalnızca yerel (cihaz içi) bildirim gönderir:

- Aşı hatırlatmaları (3 gün önce, 1 gün önce, gün sabahı)
- Vitamin/ilaç günlük hatırlatmaları

Bildirimler yalnızca cihazınızda oluşturulur ve hiçbir sunucudan gelmez. İstediğiniz zaman Ayarlar → Bildirimler menüsünden iptal edebilirsiniz.

## Yapay Zeka Asistanı (isteğe bağlı)

Ek Gıda ekranındaki asistan, ebeveynin ek gıda sorularını yanıtlamak için [OpenRouter](https://openrouter.ai) üzerinden ücretsiz açık kaynaklı dil modelleri kullanır. Bu özellik:

- **Varsayılan olarak kapalıdır.** İlk kullanımda ne gönderileceğini açıklayan bir rıza ekranı gösterilir; kabul etmeden hiçbir istek çıkmaz.
- **Yalnız siz soru yazdığınızda** istek gönderir; arka planda veri iletmez.
- Ayarlar → Yapay Zeka Asistanı bölümünden istediğiniz zaman kapatılabilir ve rıza geri alınabilir.

**Gönderilen bilgiler:** bebeğin yaşı (yalnızca ay olarak), denenen besinler, alerjen tanıtım durumları, sorunuzun metni ve aynı sohbetteki önceki mesajlar.

**Gönderilmeyen bilgiler:** bebeğin adı, doğum tarihi, fotoğrafı, kilo/boy ölçümleri, aşı, uyku, bez ve ilaç kayıtları; sizinle ilgili herhangi bir kimlik veya cihaz bilgisi.

Gönderilen içerik OpenRouter'ın ve isteği işleyen model sağlayıcısının gizlilik koşullarına tabidir ([OpenRouter gizlilik politikası](https://openrouter.ai/privacy)). Ücretsiz modeller istekleri hizmet iyileştirme amacıyla kullanabilir; bu yüzden sorularınızda kişisel bilgi yazmamanızı öneririz. Baby Care bu sohbetleri kendi sunucusunda saklamaz — Baby Care'in sunucusu yoktur. Kendi OpenRouter anahtarınızı girerseniz anahtar yalnız cihazınızın Keychain'inde tutulur.

Asistan yanıtları bilgilendirme amaçlıdır; tanı koymaz, ilaç veya doz önermez, hekim önerisinin yerini tutmaz.

## Çocuk Gizliliği

Bu uygulama 0–24 aylık bebeklerin ebeveynleri içindir. İsteğe bağlı Yapay Zeka Asistanı açılmadıkça bebeğin hiçbir bilgisi internete gönderilmez; açıldığında da yalnız yukarıda tarif edilen kimliksiz özet gider. Yetişkin kullanıcının hesabı, e-posta veya kayıt zorunluluğu yoktur.

## Veri Silme

Tüm verilerinizi istediğiniz zaman Ayarlar → "Tüm Verileri Sıfırla" seçeneğiyle kalıcı olarak silebilirsiniz. Uygulamayı kaldırdığınızda da tüm yerel veri kaldırılır.

## Tıbbi Sorumluluk Reddi

Uygulamadaki tüm içerik (aşı takvimi, gelişim rehberi, persentil grafikleri, beslenme önerileri) yalnızca bilgilendirme amaçlıdır. Hekim veya sağlık profesyoneli önerisinin yerini tutmaz. Bebeğinizin sağlığıyla ilgili her türlü karar için lütfen Aile Sağlığı Merkezi'ne veya pediatristinize danışın.

Kaynaklar: T.C. Sağlık Bakanlığı Genişletilmiş Bağışıklama Programı, Dünya Sağlık Örgütü Çocuk Büyüme Standartları, AAP gelişim rehberleri.

## Üçüncü Taraf SDK ve Servisler

Uygulamaya gömülü üçüncü taraf SDK yoktur; yalnızca Apple'ın sistem çerçeveleri (SwiftUI, SwiftData, UserNotifications, Charts) kullanılır.

Tek dış servis, yukarıda açıklanan ve yalnız açıkça etkinleştirildiğinde çalışan OpenRouter API'sidir.

## Değişiklikler

Bu politika güncellendiğinde, yeni sürüm App Store sayfasından ve uygulamanın güncel sürümüyle birlikte yayınlanır.

## İletişim

Soru veya geri bildirimleriniz için: **okkaracan@gmail.com**
