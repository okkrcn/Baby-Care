import SwiftUI
import SwiftData
import UserNotifications
import StoreKit
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NightModeStore.self) private var nightModeStore

    @Query(sort: \Baby.createdAt) private var babies: [Baby]

    @State private var showResetConfirm = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                Section("Hakkında") {
                    LabeledContent("Sürüm", value: "1.0 (Faz 3)")
                    LabeledContent("Mod", value: "Cihaz-içi (offline)")
                }

                Section {
                    Text("Verileriniz cihazınızda saklanır. Aile paylaşımı ve bulut yedekleme sonraki sürümde gelecek.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Link(destination: URL(string: "https://hsgm.saglik.gov.tr/tr/asi-takvimi.html")!) {
                        Label("T.C. Sağlık Bakanlığı — Aşı Takvimi", systemImage: "syringe")
                    }
                    Link(destination: URL(string: "https://www.who.int/tools/child-growth-standards")!) {
                        Label("DSÖ — Çocuk Büyüme Standartları", systemImage: "chart.xyaxis.line")
                    }
                    Link(destination: URL(string: "https://www.healthychildren.org")!) {
                        Label("AAP — Gelişim Rehberi (HealthyChildren.org)", systemImage: "book")
                    }
                } header: {
                    Text("Kaynaklar & Referanslar")
                } footer: {
                    Text("Uygulamadaki aşı takvimi, büyüme grafikleri ve gelişim bilgileri bu resmi kaynaklara dayanır. Tüm içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.")
                }

                Section {
                    @Bindable var night = nightModeStore
                    Picker(selection: $night.mode) {
                        ForEach(NightModeStore.Mode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    } label: {
                        Label("Gece Modu", systemImage: "moon.fill")
                    }
                    if nightModeStore.isActive {
                        Label("Şu an gece modu aktif", systemImage: "moon.stars.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Görünüm")
                } footer: {
                    Text("Gece modu koyu zemin ve kırmızı vurgu kullanır — bebek odasında göz alıştığı renkler, uykuyu daha az bozar.")
                }

                Section("Bildirimler") {
                    HStack {
                        Image(systemName: notificationIcon)
                            .foregroundStyle(notificationColor)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aşı Hatırlatmaları")
                                .font(.subheadline.weight(.medium))
                            Text(notificationStatusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if notificationStatus == .denied {
                        #if os(iOS)
                        Button {
                            openSystemSettings()
                        } label: {
                            Label("Sistem Ayarlarını Aç", systemImage: "arrow.up.right.square")
                        }
                        #endif
                    } else if notificationStatus == .notDetermined {
                        Button {
                            Task {
                                _ = await NotificationService.requestAuthorizationIfNeeded()
                                await refreshNotificationStatus()
                            }
                        } label: {
                            Label("İzin İste", systemImage: "bell.badge")
                        }
                    }
                }

                Section("Bebekler") {
                    if babies.isEmpty {
                        Text("Henüz bebek eklenmedi.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(babies) { baby in
                            HStack {
                                Image(systemName: "figure.and.child.holdinghands")
                                    .foregroundStyle(.pink)
                                Text(baby.name)
                                Spacer()
                                Text(DateFormatters.displayDate.string(from: baby.birthDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Yedekleme") {
                    NavigationLink {
                        BackupView()
                    } label: {
                        Label("Yedek Al / Geri Yükle", systemImage: "externaldrive.fill")
                    }
                }

                Section("Geri Bildirim") {
                    #if os(iOS)
                    Button {
                        sendFeedback()
                    } label: {
                        Label("Geri Bildirim Gönder", systemImage: "envelope.fill")
                    }
                    Button {
                        rateApp()
                    } label: {
                        Label("Uygulamayı Değerlendir", systemImage: "star.fill")
                    }
                    #endif
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Tüm Verileri Sıfırla", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .alert("Tüm Verileri Sil", isPresented: $showResetConfirm) {
                Button("Vazgeç", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    resetAll()
                }
            } message: {
                Text("Tüm bebek kayıtları, takipler ve aşı planı silinecek. Bu işlem geri alınamaz.")
            }
            .task {
                await refreshNotificationStatus()
            }
        }
    }

    // MARK: - Notification status

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:    return "Açık"
        case .provisional:   return "Sessiz olarak açık"
        case .ephemeral:     return "Geçici olarak açık"
        case .denied:        return "Kapalı — sistem ayarlarından açabilirsiniz"
        case .notDetermined: return "Henüz izin istenmedi"
        @unknown default:    return "Bilinmiyor"
        }
    }

    private var notificationIcon: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "bell.fill"
        case .denied:                                return "bell.slash.fill"
        default:                                     return "bell"
        }
    }

    private var notificationColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied:                                return .red
        default:                                     return .secondary
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
    }

    #if os(iOS)
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func sendFeedback() {
        let systemVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let body = """


        ---
        Cihaz: \(model)
        iOS: \(systemVersion)
        Uygulama: Baby Care 1.0
        """
        let subject = "Baby Care — Geri Bildirim"
        let to = "okkaracan@gmail.com"

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        if let scene {
            AppStore.requestReview(in: scene)
        }
    }
    #endif

    // MARK: - Reset

    private func resetAll() {
        do {
            try modelContext.delete(model: Baby.self)
            try modelContext.delete(model: FeedingRecord.self)
            try modelContext.delete(model: SleepRecord.self)
            try modelContext.delete(model: DiaperRecord.self)
            try modelContext.delete(model: VaccinationRecord.self)
            try modelContext.delete(model: GrowthRecord.self)
            try modelContext.delete(model: Medication.self)
            try modelContext.delete(model: MedicationDose.self)
            try modelContext.delete(model: PediatricContact.self)
            try modelContext.save()
            Task {
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
            }
        } catch {
            print("Sıfırlama hatası: \(error)")
        }
    }
}
