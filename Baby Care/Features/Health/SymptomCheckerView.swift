import SwiftUI

struct SymptomCheckerView: View {
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Bebeğinizde fark ettiğiniz durumu seçin. Yaşa göre uygun aksiyon önerilir.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SymptomCatalog.categories) { category in
                        NavigationLink {
                            SymptomDetailView(category: category)
                        } label: {
                            categoryCard(category)
                        }
                        .buttonStyle(.plain)
                    }
                }

                disclaimerCard
            }
            .padding()
        }
        .navigationTitle("Bu Normal Mi?")
        .inlineNavigationTitle()
    }

    private func categoryCard(_ category: SymptomCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundStyle(category.color)
                .frame(width: 44, height: 44)
                .background(category.color.opacity(0.15), in: .circle)

            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(category.prompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                Text("Önemli Uyarı")
                    .font(.subheadline.weight(.semibold))
            }
            Text("Bu rehber bilgilendirme amaçlıdır ve hekim muayenesinin yerini tutmaz. Şüphede kaldığınızda mutlaka pediatristinize veya Aile Sağlığı Merkezi'ne başvurun. Acil durumda **112**'yi arayın.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.orange.opacity(0.08), in: .rect(cornerRadius: 14))
    }
}
