import SwiftUI

struct FirstAidView: View {
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Acil durumlar için hızlı, görsel rehber. Önce 112'yi aramayı unutmayın.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                #if os(iOS)
                Button {
                    if let url = URL(string: "tel://112") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("112 Acil Servisi Ara", systemImage: "phone.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.red, in: .rect(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .buttonStyle(.plain)
                #endif

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(FirstAidCatalog.scenarios) { scenario in
                        NavigationLink {
                            FirstAidDetailView(scenario: scenario)
                        } label: {
                            scenarioCard(scenario)
                        }
                        .buttonStyle(.plain)
                    }
                }

                disclaimer
            }
            .padding()
        }
        .navigationTitle("İlk Yardım")
        .inlineNavigationTitle()
    }

    private func scenarioCard(_ scenario: FirstAidScenario) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: scenario.icon)
                .font(.title2)
                .foregroundStyle(scenario.color)
                .frame(width: 44, height: 44)
                .background(scenario.color.opacity(0.15), in: .circle)

            Text(scenario.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(scenario.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if scenario.callEmergency {
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                    Text("Önce 112")
                        .font(.caption2.weight(.semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.red.opacity(0.15), in: .capsule)
                .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    private var disclaimer: some View {
        Text("Bu rehber bilgilendirme amaçlıdır ve profesyonel ilk yardım eğitiminin yerini tutmaz. Mümkünse Kızılay veya Sağlık Bakanlığı sertifikalı temel ilk yardım kursuna katılın. Acil durumlarda her saniye kritiktir — önce 112'yi arayın, ardından bu rehberi takip edin.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(.orange.opacity(0.08), in: .rect(cornerRadius: 14))
    }
}

#if os(iOS)
import UIKit
#endif
