import SwiftUI
import SwiftData

/// Ek gıda yapay zeka asistanı: ebeveynin bebeğin kayıtlarına dayanarak
/// soru sorduğu sohbet ekranı.
///
/// Üç kapı sırayla geçilir: rıza → yapılandırma → sohbet. Hiçbiri
/// atlanamaz; rıza verilmeden ağ isteği çıkmaz.
struct SolidFoodAssistantView: View {
    let baby: Baby

    @Environment(\.modelContext) private var modelContext
    @Environment(AIAssistantStore.self) private var store

    @Query(sort: \SolidFoodRecord.servedAt, order: .reverse) private var allSolids: [SolidFoodRecord]
    @Query private var allIntroductions: [AllergenIntroduction]

    @State private var history: [ChatMessage] = []
    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var answeringModel: String?
    @State private var showSettings = false

    private var context: AssistantContext {
        AssistantContext.make(
            ageMonths: baby.ageInMonths,
            solids: allSolids.filter { $0.babyID == baby.id },
            introductions: allIntroductions.filter { $0.babyID == baby.id }
        )
    }

    var body: some View {
        Group {
            if !store.hasConsented || !store.isEnabled {
                AIConsentView(onAccept: { store.acceptConsent() })
            } else if !store.configuration.isConfigured {
                notConfiguredView
            } else {
                chat
            }
        }
        .navigationTitle("Asistan")
        .inlineNavigationTitle()
        .sheet(isPresented: $showSettings) {
            NavigationStack { AIAssistantSettingsView() }
        }
    }

    // MARK: - Yapılandırılmadı

    private var notConfiguredView: some View {
        ContentUnavailableView {
            Label("Anahtar gerekli", systemImage: "key.slash")
        } description: {
            Text("Asistan OpenRouter'ın ücretsiz modellerini kullanır. Ücretsiz bir OpenRouter anahtarı alıp Ayarlar'a girdiğinizde çalışır.")
        } actions: {
            Button("Anahtar ekle") { showSettings = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Sohbet

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        disclaimerCard

                        if history.isEmpty {
                            suggestions
                        }

                        ForEach(Array(history.enumerated()), id: \.offset) { index, message in
                            bubble(message)
                                .id(index)
                        }

                        if isSending {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Yanıt hazırlanıyor…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: history.count) {
                    withAnimation { proxy.scrollTo(history.count - 1, anchor: .bottom) }
                }
                .onChange(of: isSending) {
                    if isSending { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                }
            }

            Divider()
            composer
        }
        .task { await store.refreshModelsIfNeeded() }
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Bilgilendirme amaçlı", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
            Text(SolidFoodAssistant.disclaimer)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let answeringModel {
                Text("Model: \(answeringModel)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brown.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Örnek sorular")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(SolidFoodAssistant.suggestedQuestions(for: context), id: \.self) { question in
                Button {
                    Task { await send(question) }
                } label: {
                    HStack {
                        Text(question)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.brown)
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
        }
        .padding(.horizontal)
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.content)
                .font(.subheadline)
                .textSelection(.enabled)
                .padding(10)
                .background(
                    message.role == .user ? Color.brown.opacity(0.18) : Color.secondary.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Sorunuzu yazın…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .disabled(isSending)

            Button {
                let question = draft
                Task { await send(question) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(isSending || draft.trimmingCharacters(in: .whitespaces).isEmpty)

            if !history.isEmpty {
                Button {
                    history.removeAll()
                    errorMessage = nil
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                }
                .accessibilityLabel("Sohbeti temizle")
                .disabled(isSending)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Gönderim

    private func send(_ question: String) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let client = store.client, !isSending else { return }

        errorMessage = nil
        isSending = true
        draft = ""

        let messages = SolidFoodAssistant.messages(context: context, history: history, question: trimmed)
        history.append(.user(trimmed))

        defer { isSending = false }
        do {
            let result = try await client.complete(messages: messages, models: store.modelChain)
            history.append(.assistant(result.text))
            answeringModel = result.model
        } catch let error as OpenRouterError {
            errorMessage = error.errorDescription
            if error == .rateLimited || error == .noFreeModelAvailable {
                await store.refreshModelsIfNeeded(force: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Rıza

/// İlk kullanımda gösterilen rıza ekranı. Uygulamanın geri kalanı hiçbir
/// veri göndermediği için burada ne gittiği açıkça yazılır.
struct AIConsentView: View {
    let onAccept: @MainActor () -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Yapay zeka asistanı", systemImage: "sparkles")
                        .font(.headline)
                    Text("Asistan, bebeğinizin ek gıda kayıtlarına bakarak yaşa uygun öneriler verir. Yanıtlar OpenRouter üzerinden ücretsiz açık modellerle üretilir; uygulama bunun için ücret almaz.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Ne gönderilir?") {
                consentRow("checkmark.circle", "Bebeğin yaşı (yalnız ay olarak)")
                consentRow("checkmark.circle", "Denenen besinler ve alerjen durumları")
                consentRow("checkmark.circle", "Sorunuzun metni")
            }

            Section("Ne gönderilmez?") {
                consentRow("xmark.circle", "Bebeğin adı, doğum tarihi, fotoğrafı")
                consentRow("xmark.circle", "Kilo, boy, aşı, uyku ve bez kayıtları")
                consentRow("xmark.circle", "Sizinle ilgili herhangi bir kimlik bilgisi")
            }

            Section {
                Text("Sorularınız OpenRouter'a ve seçtiği model sağlayıcısına iletilir; onların gizlilik koşulları geçerlidir. Ücretsiz modeller istekleri eğitim için kullanabilir — sorularınızda kişisel bilgi yazmayın. Asistanı Ayarlar'dan istediğiniz zaman kapatabilirsiniz.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Link(destination: URL(string: "https://openrouter.ai/privacy")!) {
                    Label("OpenRouter gizlilik politikası", systemImage: "link")
                        .font(.caption)
                }
            }

            Section {
                Text(SolidFoodAssistant.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    onAccept()
                } label: {
                    Label("Kabul ediyorum, asistanı aç", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    private func consentRow(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
    }
}
