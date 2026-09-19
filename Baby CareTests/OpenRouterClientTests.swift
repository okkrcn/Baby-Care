import Testing
import Foundation
@testable import Baby_Care

/// Ağ yerine sabit yanıt döndüren aktarım; gönderilen isteği de saklar.
nonisolated final class StubTransport: AITransport, @unchecked Sendable {
    let status: Int
    let body: String
    private(set) var lastRequest: URLRequest?

    init(status: Int = 200, body: String) {
        self.status = status
        self.body = body
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }
}

struct OpenRouterClientTests {

    private let configured = AIConfiguration(apiKey: "sk-or-v1-test")

    @Test func sendsBearerHeaderAndModelChain() async throws {
        let transport = StubTransport(body: #"{"model":"m/one:free","choices":[{"message":{"role":"assistant","content":"  Merhaba  "}}]}"#)
        let client = OpenRouterClient(configuration: configured, transport: transport)

        let result = try await client.complete(
            messages: [.system("s"), .user("soru")],
            models: ["m/one:free", "m/two:free"]
        )

        #expect(result.text == "Merhaba")
        #expect(result.model == "m/one:free")

        let request = try #require(transport.lastRequest)
        #expect(request.url?.path.hasSuffix("/chat/completions") == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-or-v1-test")
        #expect(request.value(forHTTPHeaderField: "X-Title") == "Baby Care")

        let json = try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as? [String: Any]
        #expect(json?["model"] as? String == "m/one:free")
        #expect(json?["models"] as? [String] == ["m/one:free", "m/two:free"])
        #expect((json?["messages"] as? [[String: Any]])?.count == 2)
    }

    @Test func proxyModeSendsNoAuthorizationHeader() async throws {
        let proxy = AIConfiguration(baseURL: URL(string: "https://proxy.example/api/v1")!, usesProxy: true)
        let transport = StubTransport(body: #"{"choices":[{"message":{"content":"ok"}}]}"#)
        let client = OpenRouterClient(configuration: proxy, transport: transport)

        _ = try await client.complete(messages: [.user("x")], models: ["m:free"])

        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(transport.lastRequest?.url?.absoluteString == "https://proxy.example/api/v1/chat/completions")
    }

    @Test func notConfiguredThrowsBeforeNetwork() async {
        let transport = StubTransport(body: "{}")
        let client = OpenRouterClient(configuration: AIConfiguration(), transport: transport)

        await #expect(throws: OpenRouterError.notConfigured) {
            try await client.complete(messages: [.user("x")], models: ["m:free"])
        }
        #expect(transport.lastRequest == nil)
    }

    @Test func statusCodesMapToErrors() async {
        for (status, expected) in [(401, OpenRouterError.unauthorized), (429, .rateLimited)] {
            let client = OpenRouterClient(configuration: configured, transport: StubTransport(status: status, body: "{}"))
            await #expect(throws: expected) {
                try await client.complete(messages: [.user("x")], models: ["m:free"])
            }
        }
    }

    @Test func apiErrorInBodyIsSurfaced() async {
        let transport = StubTransport(body: #"{"error":{"code":400,"message":"bad model"}}"#)
        let client = OpenRouterClient(configuration: configured, transport: transport)
        await #expect(throws: OpenRouterError.server(status: 400, message: "bad model")) {
            try await client.complete(messages: [.user("x")], models: ["m:free"])
        }
    }

    @Test func emptyContentIsAnError() async {
        let transport = StubTransport(body: #"{"choices":[{"message":{"content":"   "}}]}"#)
        let client = OpenRouterClient(configuration: configured, transport: transport)
        await #expect(throws: OpenRouterError.emptyResponse) {
            try await client.complete(messages: [.user("x")], models: ["m:free"])
        }
    }

    @Test func listModelsParsesData() async throws {
        let transport = StubTransport(body: #"{"data":[{"id":"a/b:free","name":"B","context_length":8192,"pricing":{"prompt":"0","completion":"0"}}]}"#)
        let client = OpenRouterClient(configuration: configured, transport: transport)
        let models = try await client.listModels()
        #expect(models.count == 1)
        #expect(models[0].id == "a/b:free")
        #expect(models[0].contextLength == 8192)
    }
}
