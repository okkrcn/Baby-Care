import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .home
    /// `babycare://dis` gibi bağlantılarda Bebek sekmesinin açacağı ekran.
    @State private var pendingTeethLink = false

    var body: some View {
        TabView(selection: $selection) {
            Tab("Ana", systemImage: "house.fill", value: AppTab.home) {
                DashboardView()
            }

            Tab("Takip", systemImage: "list.bullet.clipboard.fill", value: AppTab.tracking) {
                TrackingView()
            }

            Tab("Aşı", systemImage: "syringe.fill", value: AppTab.vaccination) {
                VaccinationView()
            }

            Tab("Bebek", systemImage: "figure.and.child.holdinghands", value: AppTab.baby) {
                BabyProfileView(openTeeth: $pendingTeethLink)
            }

            Tab("Ayarlar", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else { return }
            selection = link.tab
            pendingTeethLink = (link == .teeth)
        }
    }
}
