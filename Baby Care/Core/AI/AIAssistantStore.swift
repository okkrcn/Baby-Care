import Foundation
import Observation

/// Yapay zeka asistanının kullanıcı tercihleri ve istemci yaşam döngüsü.
///
/// Varsayılan kapalıdır: uygulama çevrimdışı ve veri göndermeyen bir
/// araç olarak konumlanır; ebeveyn asistanı açıp rıza vermeden hiçbir
/// istek çıkmaz. Bu iki karar (`isEnabled`, `hasConsented`) UserDefaults'ta,
/// kullanıcı anahtarı ise Keychain'de tutulur.
@MainActor
@Observable
final class AIAssistantStore {
    private enum Keys {
        static let enabled   = "ai.assistant.enabled"
        static let consented = "ai.assistant.consentAccepted"
    }

    /// Ayarlar'daki ana anahtar.
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }

    /// Ebeveyn, verilerin OpenRouter'a gideceğini okuyup kabul etti.
    private(set) var hasConsented: Bool {
        didSet { UserDefaults.standard.set(hasConsented, forKey: Keys.consented) }
    }

    /// Kullanıcının Ayarlar'da girdiği kendi anahtarı var mı.
    private(set) var hasUserKey: Bool

    private(set) var configuration: AIConfiguration
    private(set) var client: OpenRouterClient?

    /// `/models` çağrısından seçilen ücretsiz model zinciri; henüz çekilmediyse
    /// tercih listesi kullanılır.
    private(set) var modelChain: [String] = FreeModelCatalog.preferred
    private(set) var lastModelRefresh: Date?

    /// Asistan ekranının açılabilmesi için gereken üç koşul.
    var isReady: Bool { isEnabled && hasConsented && configuration.isConfigured }

    /// Anahtarın nereden geldiğini Ayarlar'da açıklamak için.
    var keySourceDescription: String {
        if hasUserKey { return "Kendi OpenRouter anahtarınız (Keychain)" }
        if configuration.usesProxy { return "Uygulama vekili — cihazda anahtar yok" }
        if configuration.isConfigured { return "Uygulama ile gelen anahtar" }
        return "Ayarlanmadı"
    }

    init() {
        let defaults = UserDefaults.standard
        self.isEnabled = defaults.bool(forKey: Keys.enabled)
        self.hasConsented = defaults.bool(forKey: Keys.consented)
        let userKey = AIKeyStore.load()
        self.hasUserKey = userKey != nil
        self.configuration = AIConfiguration.load(userKey: userKey)
        rebuildClient()
    }

    // MARK: - Tercihler

    func acceptConsent() {
        hasConsented = true
        isEnabled = true
    }

    func revokeConsent() {
        hasConsented = false
        isEnabled = false
    }

    func saveUserKey(_ key: String) {
        AIKeyStore.save(key)
        reloadConfiguration()
    }

    func removeUserKey() {
        AIKeyStore.delete()
        reloadConfiguration()
    }

    // MARK: - Model zinciri

    /// Ücretsiz model listesini en fazla günde bir tazeler. Başarısız olursa
    /// mevcut zincir korunur; bu çağrı hiçbir zaman fırlatmaz.
    func refreshModelsIfNeeded(force: Bool = false) async {
        guard let client else { return }
        if !force, let last = lastModelRefresh,
           Date.now.timeIntervalSince(last) < 24 * 3600 { return }

        guard let remote = try? await client.listModels() else { return }
        let chain = FreeModelCatalog.select(from: remote)
        if !chain.isEmpty {
            modelChain = chain
        }
        lastModelRefresh = .now
    }

    // MARK: - Private

    private func reloadConfiguration() {
        let userKey = AIKeyStore.load()
        hasUserKey = userKey != nil
        configuration = AIConfiguration.load(userKey: userKey)
        lastModelRefresh = nil
        rebuildClient()
    }

    private func rebuildClient() {
        client = configuration.isConfigured ? OpenRouterClient(configuration: configuration) : nil
    }
}
