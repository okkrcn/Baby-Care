import SwiftUI

/// Tek bir besinin kartı: üç sunum biçimi, boğulma riski, alerjen ve
/// varsa yaş bariyeri. Püre yapan da parmak besin verende de aynı karttan
/// yararlanır.
struct FoodDetailView: View {
    let item: FoodItem
    let baby: Baby

    private var isBarred: Bool {
        guard let barrier = item.ageBarrier else { return false }
        return baby.ageInMonths < barrier.minAgeMonths
    }

    private var isTooEarly: Bool {
        baby.ageInMonths < item.minAgeMonths
    }

    var body: some View {
        List {
            Section {
                badgeRow
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }

            if let barrier = item.ageBarrier {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            "\(barrier.minAgeMonths) aydan önce verilmez",
                            systemImage: "exclamationmark.octagon.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)

                        Text(barrier.reason)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let url = URL(string: barrier.sourceURL) {
                            Link("Kaynağı görüntüle", destination: url)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if let note = item.safePrepNote {
                Section {
                    Label {
                        Text(note)
                            .font(.footnote)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(item.chokingRisk == .high ? .red : .orange)
                    }
                } header: {
                    Text("Güvenli hazırlama")
                }
            }

            Section("Nasıl verilir") {
                prepRow(SolidFoodMethod.puree, text: item.prepPuree)
                prepRow(SolidFoodMethod.fingerFood, text: item.prepFingerFood)
                prepRow(SolidFoodMethod.familyMeal, text: item.prepFamilyMeal)
            }

            if let allergen = item.allergen {
                allergenSection(allergen)
            }

            Section {
                Text("Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz. Bebeğinizin beslenmesiyle ilgili kararlar için pediatristinize danışın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.name)
        .inlineNavigationTitle()
    }

    // MARK: - Parçalar

    private var badgeRow: some View {
        HStack(spacing: 8) {
            if item.chokingRisk != .low {
                badge(
                    item.chokingRisk.localizedTitle,
                    icon: "exclamationmark.triangle.fill",
                    color: item.chokingRisk == .high ? .red : .orange
                )
            }
            badge(item.group.localizedTitle, icon: item.group.icon, color: .brown)
            badge(ageLabel, icon: "calendar", color: isTooEarly || isBarred ? .orange : .secondary)
            Spacer(minLength: 0)
        }
    }

    private var ageLabel: String {
        if let barrier = item.ageBarrier { return "\(barrier.minAgeMonths) ay+" }
        return "\(item.minAgeMonths) ay+"
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: .capsule)
    }

    private func prepRow(_ method: SolidFoodMethod, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(method.localizedTitle, systemImage: method.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.brown)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func allergenSection(_ allergen: Allergen) -> some View {
        let info = AllergenCatalog.info(for: allergen)
        Section {
            Label(allergen.localizedTitle, systemImage: allergen.icon)
                .font(.subheadline.weight(.semibold))
            Text(info.introductionGuidance)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(info.safeServingForm)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let url = URL(string: info.sourceURL) {
                Link("Kaynağı görüntüle", destination: url)
                    .font(.caption)
            }
        } header: {
            Text("Alerjen bilgisi")
        }
    }
}
