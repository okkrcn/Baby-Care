import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var exportedURL: URL?
    @State private var showExporterSheet = false
    @State private var showImporter = false
    @State private var showImportConfirm = false
    @State private var importURL: URL?
    @State private var importMode: DataBackupService.ImportMode = .merge
    @State private var statusMessage: String?
    @State private var isError = false

    var body: some View {
        List {
            Section {
                Text("Tüm verileriniz cihazınızda saklanır. Yeni bir telefona geçtiğinizde veya cihaz değişiminde verilerinizi kaybetmemek için **düzenli yedek alın**.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Yedek Al") {
                Button {
                    createBackup()
                } label: {
                    Label("Yedek Oluştur", systemImage: "square.and.arrow.up.fill")
                }

                Text("JSON formatında bir dosya oluşturulur. Mail, AirDrop, iCloud Drive, Dropbox vb. yere kaydedebilirsiniz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Yedekten Geri Yükle") {
                Button {
                    showImporter = true
                } label: {
                    Label("Yedek Dosyası Seç", systemImage: "square.and.arrow.down.fill")
                }

                Text("Daha önce oluşturduğunuz JSON dosyasını seçin. Mevcut verilerinizi tamamen değiştirmek mi yoksa birleştirmek mi istediğinizi soracağız.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let status = statusMessage {
                Section {
                    Label(status, systemImage: isError ? "xmark.octagon.fill" : "checkmark.seal.fill")
                        .foregroundStyle(isError ? .red : .green)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Önemli", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("• Yedek dosyası kişisel veri içerir, güvendiğiniz yerde saklayın.")
                        .font(.caption)
                    Text("• Geri yükleme sırasında 'Değiştir' modu mevcut tüm verileri siler.")
                        .font(.caption)
                    Text("• 'Birleştir' modu sadece yeni kayıtları ekler (mevcutları korur).")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Yedekleme")
        .inlineNavigationTitle()
        .sheet(isPresented: $showExporterSheet) {
            if let url = exportedURL {
                ShareSheetWrapper(url: url)
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importURL = url
                    showImportConfirm = true
                }
            case .failure(let error):
                statusMessage = error.localizedDescription
                isError = true
            }
        }
        .confirmationDialog("Yedeği Nasıl Yüklemek İstersiniz?",
                            isPresented: $showImportConfirm,
                            titleVisibility: .visible) {
            Button("Mevcut Verilerle Birleştir") {
                runImport(mode: .merge)
            }
            Button("Mevcut Verileri Değiştir (Sil & Yükle)", role: .destructive) {
                runImport(mode: .replace)
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Birleştir: Sadece yeni kayıtlar eklenir.\nDeğiştir: Mevcut tüm veriler silinir, yedekten yüklenir.")
        }
    }

    private func createBackup() {
        do {
            let url = try DataBackupService.export(from: modelContext)
            exportedURL = url
            statusMessage = "Yedek oluşturuldu. Paylaşın veya kaydedin."
            isError = false
            showExporterSheet = true
        } catch {
            statusMessage = "Yedek oluşturulamadı: \(error.localizedDescription)"
            isError = true
        }
    }

    private func runImport(mode: DataBackupService.ImportMode) {
        guard let url = importURL else { return }
        do {
            let count = try DataBackupService.import(from: url, mode: mode, into: modelContext)
            statusMessage = "\(count) kayıt başarıyla içe aktarıldı."
            isError = false
        } catch {
            statusMessage = "İçe aktarma başarısız: \(error.localizedDescription)"
            isError = true
        }
    }
}

#if os(iOS)
import UIKit

struct ShareSheetWrapper: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
struct ShareSheetWrapper: View {
    let url: URL
    var body: some View {
        ShareLink(item: url)
            .padding()
    }
}
#endif
