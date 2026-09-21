import Foundation

/// OpenRouter'daki ücretsiz modellerin seçimi.
///
/// Ücretsiz modeller (`:free` son eki) zamanla değişir ve kotaları sık
/// dolar. Bu yüzden sabit bir liste yerine iki katman kullanılır:
///
///  1. `preferred`: içerik kalitesi bilinen, Türkçesi yeterli adaylar.
///  2. `/models` uç noktasından o an ücretsiz olanlar; tercih listesinde
///     olmayanlar bağlam uzunluğuna göre yedek olarak eklenir.
///
/// Model listesi çekilemezse `preferred` olduğu gibi kullanılır — OpenRouter
/// var olmayan modeli atlayıp zincirdeki sonrakine geçer.
nonisolated enum FreeModelCatalog {

    /// Sıra önemli: ilki asıl model, kalanlar yedek.
    static let preferred: [String] = [
        "meta-llama/llama-3.3-70b-instruct:free",
        "google/gemma-3-27b-it:free",
        "qwen/qwen3-235b-a22b:free",
        "deepseek/deepseek-chat-v3-0324:free",
        "mistralai/mistral-small-3.2-24b-instruct:free",
        "openai/gpt-oss-120b:free",
    ]

    /// Tek istekte gönderilecek en fazla model sayısı.
    static let maxChain = 5

    /// Asistan için gereken en küçük bağlam penceresi (sistem istemi + katalog).
    static let minimumContextLength = 8_000

    static func isFree(_ model: OpenRouterModel) -> Bool {
        guard let pricing = model.pricing else { return model.id.hasSuffix(":free") }
        return isZero(pricing.prompt) && isZero(pricing.completion)
    }

    /// Uzak listeden ücretsiz modelleri tercih sırasına göre dizer.
    static func select(from remote: [OpenRouterModel], preferred: [String] = preferred) -> [String] {
        let free = remote.filter {
            isFree($0) && isTextOnlyOutput($0) && ($0.contextLength ?? .max) >= minimumContextLength
        }
        let freeIDs = Set(free.map(\.id))

        var chain = preferred.filter { freeIDs.contains($0) }

        let extras = free
            .filter { !chain.contains($0.id) }
            .sorted { ($0.contextLength ?? 0) > ($1.contextLength ?? 0) }
            .map(\.id)
        chain.append(contentsOf: extras)

        return Array(chain.prefix(maxChain))
    }

    /// Fiyatı sıfır olan ses/görsel üreten önizleme modelleri de listede
    /// görünür; sohbet zincirine girerlerse yanıt bozulur. Alan yoksa metin sayılır.
    private static func isTextOnlyOutput(_ model: OpenRouterModel) -> Bool {
        guard let output = model.architecture?.outputModalities else { return true }
        return output == ["text"]
    }

    private static func isZero(_ price: String?) -> Bool {
        guard let price, let value = Double(price) else { return false }
        return value == 0
    }
}
