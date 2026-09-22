import Testing
import Foundation
@testable import Baby_Care

struct AIConfigurationTests {

    @Test func userKeyTakesPrecedenceOverBundledAndEnvironment() {
        let bundled = AIConfiguration.BundledSecrets(apiKey: "bundled", baseURL: nil)
        let config = AIConfiguration.load(userKey: "user", bundled: bundled, environmentKey: "env")
        #expect(config.apiKey == "user")
        #expect(config.usesProxy == false)
        #expect(config.baseURL == AIConfiguration.defaultBaseURL)
    }

    @Test func proxyBaseURLWithoutKeyMeansProxyMode() {
        let proxy = URL(string: "https://baby-care-ai.example.workers.dev/api/v1")!
        let bundled = AIConfiguration.BundledSecrets(apiKey: nil, baseURL: proxy)
        let config = AIConfiguration.load(userKey: nil, bundled: bundled, environmentKey: nil)
        #expect(config.usesProxy == true)
        #expect(config.apiKey == nil)
        #expect(config.baseURL == proxy)
        #expect(config.isConfigured == true)
    }

    @Test func bundledKeyIsUsedWhenNoUserKey() {
        let bundled = AIConfiguration.BundledSecrets(apiKey: "bundled", baseURL: nil)
        let config = AIConfiguration.load(userKey: "  ", bundled: bundled, environmentKey: nil)
        #expect(config.apiKey == "bundled")
        #expect(config.isConfigured == true)
    }

    @Test func nothingConfiguredIsNotReady() {
        let config = AIConfiguration.load(userKey: nil, bundled: .init(), environmentKey: nil)
        #expect(config.isConfigured == false)
    }

    @Test func plistParsingIgnoresBlankAndInvalidValues() {
        let parsed = AIConfiguration.BundledSecrets.parse([
            "OPENROUTER_API_KEY": "   ",
            "OPENROUTER_BASE_URL": "not a url",
        ])
        #expect(parsed.apiKey == nil)
        #expect(parsed.baseURL == nil)

        let valid = AIConfiguration.BundledSecrets.parse([
            "OPENROUTER_API_KEY": "sk-or-v1-abc",
            "OPENROUTER_BASE_URL": "https://example.com/api/v1",
        ])
        #expect(valid.apiKey == "sk-or-v1-abc")
        #expect(valid.baseURL?.host == "example.com")
    }
}

struct FreeModelCatalogTests {

    private func model(_ id: String, prompt: String? = "0", completion: String? = "0", context: Int? = 32_000) -> OpenRouterModel {
        let json = """
        {"id":"\(id)","name":"\(id)","context_length":\(context.map { String($0) } ?? "null"),
         "pricing":{"prompt":\(prompt.map { "\"\($0)\"" } ?? "null"),"completion":\(completion.map { "\"\($0)\"" } ?? "null")}}
        """
        return try! JSONDecoder().decode(OpenRouterModel.self, from: Data(json.utf8))
    }

    @Test func paidModelsAreNotFree() {
        #expect(FreeModelCatalog.isFree(model("a/b:free")) == true)
        #expect(FreeModelCatalog.isFree(model("a/b", prompt: "0.000001")) == false)
        #expect(FreeModelCatalog.isFree(model("a/b", prompt: "0", completion: "0.00002")) == false)
    }

    @Test func preferredOrderIsKeptAndPaidModelsDropped() {
        let remote = [
            model("x/other-big:free", context: 128_000),
            model(FreeModelCatalog.preferred[1]),
            model("paid/model", prompt: "0.01"),
            model(FreeModelCatalog.preferred[0]),
        ]
        let chain = FreeModelCatalog.select(from: remote)
        #expect(chain.first == FreeModelCatalog.preferred[0])
        #expect(chain[1] == FreeModelCatalog.preferred[1])
        #expect(chain.contains("x/other-big:free"))
        #expect(!chain.contains("paid/model"))
    }

    @Test func tinyContextModelsAreSkipped() {
        let remote = [model("tiny/model:free", context: 2_000), model("ok/model:free", context: 16_000)]
        #expect(FreeModelCatalog.select(from: remote) == ["ok/model:free"])
    }

    @Test func nonTextOutputModelsAreSkipped() throws {
        let json = """
        {"id":"music/gen","context_length":1000000,"pricing":{"prompt":"0","completion":"0"},
         "architecture":{"output_modalities":["text","audio"]}}
        """
        let music = try JSONDecoder().decode(OpenRouterModel.self, from: Data(json.utf8))
        #expect(FreeModelCatalog.select(from: [music, model("ok/model:free")]) == ["ok/model:free"])
    }

    @Test func chainIsCapped() {
        let remote = (0..<10).map { model("m/\($0):free", context: 100_000 - $0) }
        #expect(FreeModelCatalog.select(from: remote).count == FreeModelCatalog.maxChain)
    }
}
