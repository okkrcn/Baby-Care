import Foundation

// MARK: - Aktarım
//
// Proje varsayılan olarak MainActor izolasyonludur (SWIFT_DEFAULT_ACTOR_ISOLATION).
// Bu dosyadaki tel-format tipleri aktör içinde kodlanıp çözüldüğü için `nonisolated`.

/// Ağ katmanı soyutlaması; testlerde sahte yanıt vermek için.
nonisolated protocol AITransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

nonisolated extension URLSession: AITransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

// MARK: - Mesaj tipleri

nonisolated struct ChatMessage: Codable, Sendable, Equatable {
    enum Role: String, Codable, Sendable {
        case system, user, assistant
    }

    let role: Role
    let content: String

    static func system(_ text: String) -> ChatMessage { .init(role: .system, content: text) }
    static func user(_ text: String) -> ChatMessage { .init(role: .user, content: text) }
    static func assistant(_ text: String) -> ChatMessage { .init(role: .assistant, content: text) }
}

nonisolated struct ChatCompletionResult: Sendable, Equatable {
    let text: String
    /// Yanıtı üreten model (fallback zincirinde hangisi yanıtladıysa).
    let model: String?
}

nonisolated struct OpenRouterModel: Decodable, Sendable, Equatable {
    struct Pricing: Decodable, Sendable, Equatable {
        let prompt: String?
        let completion: String?
    }

    struct Architecture: Decodable, Sendable, Equatable {
        let outputModalities: [String]?

        enum CodingKeys: String, CodingKey {
            case outputModalities = "output_modalities"
        }
    }

    let id: String
    let name: String?
    let contextLength: Int?
    let pricing: Pricing?
    let architecture: Architecture?

    enum CodingKeys: String, CodingKey {
        case id, name, pricing, architecture
        case contextLength = "context_length"
    }
}

nonisolated enum OpenRouterError: LocalizedError, Equatable {
    case notConfigured
    case unauthorized
    case rateLimited
    case noFreeModelAvailable
    case server(status: Int, message: String?)
    case emptyResponse
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Yapay zeka asistanı için OpenRouter anahtarı ayarlanmamış. Ayarlar → Yapay Zeka Asistanı bölümünden ekleyebilirsiniz."
        case .unauthorized:
            return "OpenRouter anahtarı geçersiz veya süresi dolmuş."
        case .rateLimited:
            return "Ücretsiz model kotası şu an dolu. Birkaç dakika sonra tekrar deneyin."
        case .noFreeModelAvailable:
            return "Şu an kullanılabilir ücretsiz model bulunamadı."
        case .server(let status, let message):
            return message ?? "Sunucu hatası (\(status))."
        case .emptyResponse:
            return "Modelden boş yanıt geldi."
        case .transport(let message):
            return "Bağlantı kurulamadı: \(message)"
        }
    }
}

// MARK: - İstemci

/// OpenRouter chat-completions istemcisi.
///
/// Yalnız `chat/completions` ve `models` uç noktalarını kullanır. Model
/// listesi `models` alanıyla verilir: ilk model asıl, kalanlar yedek —
/// ücretsiz modellerin kotası sık dolduğu için OpenRouter'ın kendi
/// fallback yönlendirmesine yaslanılır.
actor OpenRouterClient {
    private let configuration: AIConfiguration
    private let transport: AITransport

    init(configuration: AIConfiguration, transport: AITransport = URLSession.shared) {
        self.configuration = configuration
        self.transport = transport
    }

    func complete(
        messages: [ChatMessage],
        models: [String],
        temperature: Double = 0.4,
        maxTokens: Int = 700
    ) async throws -> ChatCompletionResult {
        guard configuration.isConfigured else { throw OpenRouterError.notConfigured }
        guard let primary = models.first else { throw OpenRouterError.noFreeModelAvailable }

        let body = CompletionRequest(
            model: primary,
            models: models.count > 1 ? models : nil,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens
        )

        var request = makeRequest(path: "chat/completions", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await perform(request)
        try Self.validate(response, data: data)

        let decoded = try Self.decode(CompletionResponse.self, from: data)
        if let error = decoded.error {
            throw OpenRouterError.server(status: error.code ?? 0, message: error.message)
        }
        let text = decoded.choices?.first?.message?.content?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw OpenRouterError.emptyResponse }
        return ChatCompletionResult(text: text, model: decoded.model)
    }

    func listModels() async throws -> [OpenRouterModel] {
        let request = makeRequest(path: "models", method: "GET")
        let (data, response) = try await perform(request)
        try Self.validate(response, data: data)
        return try Self.decode(ModelsResponse.self, from: data).data
    }

    // MARK: - Private

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: configuration.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let key = configuration.apiKey, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        // OpenRouter panosunda uygulama adının görünmesi için (isteğe bağlı).
        request.setValue(configuration.appReferer, forHTTPHeaderField: "HTTP-Referer")
        request.setValue(configuration.appTitle, forHTTPHeaderField: "X-Title")
        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await transport.send(request)
        } catch let error as OpenRouterError {
            throw error
        } catch {
            throw OpenRouterError.transport(error.localizedDescription)
        }
    }

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200..<300: return
        case 401, 403:  throw OpenRouterError.unauthorized
        case 429:       throw OpenRouterError.rateLimited
        default:
            let message = (try? decode(CompletionResponse.self, from: data))?.error?.message
            throw OpenRouterError.server(status: http.statusCode, message: message)
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw OpenRouterError.server(status: 0, message: "Yanıt çözümlenemedi.")
        }
    }

    // MARK: - Tel formatı

    nonisolated struct CompletionRequest: Encodable {
        let model: String
        let models: [String]?
        let messages: [ChatMessage]
        let temperature: Double
        let maxTokens: Int

        enum CodingKeys: String, CodingKey {
            case model, models, messages, temperature
            case maxTokens = "max_tokens"
        }
    }

    nonisolated struct CompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String?
                let content: String?
            }
            let message: Message?
        }
        struct APIError: Decodable {
            let code: Int?
            let message: String?
        }
        let model: String?
        let choices: [Choice]?
        let error: APIError?
    }

    nonisolated struct ModelsResponse: Decodable {
        let data: [OpenRouterModel]
    }
}
