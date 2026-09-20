import SwiftUI

/// Ayarlar → Yapay Zeka Asistanı.
struct AIAssistantSettingsView: View {
    @Environment(AIAssistantStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var keyDraft = ""
    @State private var showRevokeConfirm = false
    @State private var isTesting = false
    @State private var testResult: String?

    var body: some View {
        @Bindable var store = store

        List {
            Section {
                Toggle(isOn: $store.isEnabled) {
                    Label("Asistanı kullan", systemImage: "sparkles")
                }
                .disabled(!store.hasConsented)

                LabeledContent("Rıza", value: store.hasConsented ? "Verildi" : "Verilmedi")
                LabeledContent("Anahtar", value: store.keySourceDescription)
            } header: {
                Text("Durum")
            } footer: {
                Text(store.hasConsented
                     ? "Asistan yalnız Ek Gıda ekranından, siz soru yazdığınızda istek gönderir."
                     : "Rıza, Ek Gıda → Asistan sekmesinde ilk açılışta istenir.")
            }

            Section {
                SecureField("sk-or-v1-…", text: $keyDraft)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                Button {
                    store.saveUserKey(keyDraft)
                    keyDraft = ""
                    testResult = nil
                } label: {
                    Label("Anahtarı kaydet", systemImage: "key.fill")
                }
                .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)

                if store.hasUserKey {
                    Button(role: .destructive) {
                        store.removeUserKey()
                        testResult = nil
                    } label: {
                        Label("Anahtarı kaldır", systemImage: "key.slash")
                    }
                }

                Link(destination: URL(string: "https://openrouter.ai/keys")!) {
                    Label("OpenRouter'da ücretsiz anahtar al", systemImage: "arrow.up.right.square")
                }
            } header: {
                Text("Kendi OpenRouter anahtarınız")
            } footer: {
                Text("Anahtar yalnız bu cihazın Keychain'inde saklanır; yedeklere ve iCloud'a girmez. Ücretsiz modeller için OpenRouter hesabında bakiye gerekmez.")
            }

            Section {
                ForEach(store.modelChain, id: \.self) { model in
                    Text(model)
                        .font(.caption.monospaced())
                }
                Button {
                    Task {
                        isTesting = true
                        await store.refreshModelsIfNeeded(force: true)
                        isTesting = false
                        testResult = store.lastModelRefresh == nil
                            ? "Model listesi alınamadı; tercih listesi kullanılacak."
                            : "Model listesi güncellendi."
                    }
                } label: {
                    if isTesting {
                        ProgressView()
                    } else {
                        Label("Ücretsiz modelleri yenile", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(!store.configuration.isConfigured || isTesting)

                if let testResult {
                    Text(testResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Model zinciri")
            } footer: {
                Text("İlk model asıl, kalanlar yedektir. Ücretsiz modellerin kotası dolduğunda OpenRouter sıradakine geçer.")
            }

            if store.hasConsented {
                Section {
                    Button(role: .destructive) {
                        showRevokeConfirm = true
                    } label: {
                        Label("Rızayı geri al ve asistanı kapat", systemImage: "hand.raised.fill")
                    }
                }
            }
        }
        .navigationTitle("Yapay Zeka Asistanı")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Kapat") { dismiss() }
            }
        }
        .alert("Rızayı geri al", isPresented: $showRevokeConfirm) {
            Button("Vazgeç", role: .cancel) { }
            Button("Geri al", role: .destructive) { store.revokeConsent() }
        } message: {
            Text("Asistan kapanır ve bir daha açmak istediğinizde rıza ekranı yeniden gösterilir. Kayıtlarınız silinmez.")
        }
    }
}
