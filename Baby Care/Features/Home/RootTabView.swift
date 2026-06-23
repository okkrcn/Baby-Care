import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Ana", systemImage: "house.fill") {
                DashboardView()
            }

            Tab("Takip", systemImage: "list.bullet.clipboard.fill") {
                TrackingView()
            }

            Tab("Aşı", systemImage: "syringe.fill") {
                VaccinationView()
            }

            Tab("Bebek", systemImage: "figure.and.child.holdinghands") {
                BabyProfileView()
            }

            Tab("Ayarlar", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}
