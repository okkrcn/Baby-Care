import Foundation

/// Yapay zeka asistanının çalışma zamanı ayarları.
///
/// Uygulama gelir hedefi olmadan yayınlanır; bu yüzden yalnızca OpenRouter'ın
/// ücretsiz (`:free`) modelleri kullanılır. Anahtar üç yerden gelebilir,
/// öncelik sırasıyla:
///
///  1. Kullanıcının Ayarlar'da girdiği kendi OpenRouter anahtarı (Keychain).
///  2. Paket içindeki `AISecrets.plist` (git'e girmez; geliştirme ve
///     TestFlight için). Paket içine konan anahtar cihazdan çıkarılabilir;
///     mağaza sürümünde bunun yerine `OPENROUTER_BASE_URL`'i anahtarı
///     kendi tutan bir vekile (bkz. `proxy/`) çevirin.
///  3. `OPENROUTER_API_KEY` ortam değişkeni (Xcode scheme, yalnız Debug).
///
/// Vekil kullanıldığında anahtar cihazda hiç bulunmaz; `isConfigured`
/// yalnız taban adresin ayarlı olmasını ister.
nonisolated struct AIConfiguration: Sendable, Equatable {
    static let defaultBaseURL = URL(string: "https://openrouter.ai/api/v1")!

    /// Chat completions ve models uç noktalarının önündeki taban adres.
    var baseURL: URL
    /// OpenRouter anahtarı; vekil kullanılıyorsa nil olabilir.
    var apiKey: String?
    /// Anahtar bir vekilde tutuluyorsa true — cihazda anahtar aranmaz.
    var usesProxy: Bool
    /// OpenRouter panosunda uygulamanın görünmesi için gönderilen kimlik.
    var appTitle: String
    var appReferer: String

    var isConfigured: Bool {
        usesProxy || !(apiKey ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(
        baseURL: URL = AIConfiguration.defaultBaseURL,
        apiKey: String? = nil,
        usesProxy: Bool = false,
        appTitle: String = "Baby Care",
        appReferer: String = "https://okkrcn.github.io/Baby-Care/"
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.usesProxy = usesProxy
        self.appTitle = appTitle
        self.appReferer = appReferer
    }

    // MARK: - Yükleme

    /// Öncelik sırasına göre çalışma zamanı yapılandırmasını kurar.
    static func load(
        userKey: String?,
        bundled: BundledSecrets = .load(),
        environmentKey: String? = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
    ) -> AIConfiguration {

        if let userKey, !userKey.trimmingCharacters(in: .whitespaces).isEmpty {
            return AIConfiguration(apiKey: userKey)
        }

        if let proxy = bundled.baseURL, bundled.apiKey == nil {
            return AIConfiguration(baseURL: proxy, usesProxy: true)
        }

        if let key = bundled.apiKey {
            return AIConfiguration(baseURL: bundled.baseURL ?? defaultBaseURL, apiKey: key)
        }

        #if DEBUG
        if let environmentKey, !environmentKey.isEmpty {
            return AIConfiguration(apiKey: environmentKey)
        }
        #endif

        return AIConfiguration()
    }

    /// `AISecrets.plist` içeriği. Dosya yoksa tüm alanlar nil döner.
    struct BundledSecrets: Sendable, Equatable {
        var apiKey: String?
        var baseURL: URL?

        static func load(bundle: Bundle = .main) -> BundledSecrets {
            guard let url = bundle.url(forResource: "AISecrets", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
            else { return BundledSecrets() }
            return parse(dict)
        }

        static func parse(_ dict: [String: Any]) -> BundledSecrets {
            var secrets = BundledSecrets()
            if let key = dict["OPENROUTER_API_KEY"] as? String,
               !key.trimmingCharacters(in: .whitespaces).isEmpty {
                secrets.apiKey = key
            }
            if let raw = dict["OPENROUTER_BASE_URL"] as? String,
               let url = URL(string: raw.trimmingCharacters(in: .whitespaces)),
               url.scheme != nil {
                secrets.baseURL = url
            }
            return secrets
        }
    }
}
