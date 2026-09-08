import SwiftUI
import SwiftData

/// Dokuz major alerjenin tanıtım durumu.
///
/// Panelin üstündeki açıklama iki kaynağı da gösterir: uygulama güncel
/// uluslararası konsensüsü esas alır, TÜBER 2022'nin 3–5 gün önerisini
/// gizlemez.
struct AllergenPanelView: View {
    let baby: Baby

    @Environment(\.modelContext) private var modelContext
    @Query private var allIntroductions: [AllergenIntroduction]

    private var introductions: [AllergenIntroduction] {
        allIntroductions
            .filter { $0.babyID == baby.id }
            .sorted {
                let lhs = Allergen.allCases.firstIndex(of: $0.allergen) ?? 0
                let rhs = Allergen.allCases.firstIndex(of: $1.allergen) ?? 0
                return lhs < rhs
            }
    }

    var body: some View {
        List {
            Section {
                Text("Güncel uluslararası kılavuzlar (ESPGHAN, AAP, EAACI) alerjenlerin geciktirilmemesini, tamamlayıcı beslenmeyle birlikte yaklaşık 6. ayda tanıtılmasını öneriyor. T.C. Sağlık Bakanlığı Türkiye Beslenme Rehberi ise yeni besinler arasında 3–5 gün bırakılmasını öneriyor; gözlem için bunu tercih edebilirsiniz.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Link(destination: URL(string: "https://www.espghan.org/dam/jcr:ea5c9b57-9315-44b7-b9a0-149511b96654/ESPGHAN%20Infant%20Feeding%20Campaign%20-%20Guidance%20Summary.pdf")!) {
                    Label("ESPGHAN — Tamamlayıcı beslenme özeti", systemImage: "link")
                        .font(.caption)
                }
                Link(destination: URL(string: "https://hsgm.saglik.gov.tr/depo/birimler/saglikli-beslenme-ve-hareketli-hayat-db/Dokumanlar/Rehberler/Turkiye_Beslenme_Rehber_TUBER_2022_min.pdf")!) {
                    Label("T.C. Sağlık Bakanlığı — TÜBER 2022", systemImage: "link")
                        .font(.caption)
                }
            } header: {
                Text("Tanıtım yaklaşımı")
            }

            Section {
                ForEach(introductions) { intro in
                    NavigationLink {
                        AllergenDetailView(introduction: intro)
                    } label: {
                        row(intro)
                    }
                }
            } header: {
                Text("Durum")
            } footer: {
                Text("Tepki gözlenen besin, hekim değerlendirmesi olmadan evde tekrar denenmez.")
            }
        }
        .navigationTitle("Alerjenler")
        .inlineNavigationTitle()
        .task {
            // Eksik kayıtları oluştur (ilk açılışta dokuz satır hazır olsun).
            _ = SolidFoodService.introductions(for: baby.id, in: modelContext)
        }
    }

    private func row(_ intro: AllergenIntroduction) -> some View {
        HStack(spacing: 10) {
            Image(systemName: intro.status.icon)
                .font(.footnote)
                .foregroundStyle(statusColor(intro.status))
                .frame(width: 28, height: 28)
                .background(statusColor(intro.status).opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(intro.allergen.localizedTitle)
                    .font(.subheadline.weight(.medium))
                Text(subtitle(intro))
                    .font(.caption2)
                    .foregroundStyle(intro.needsRegularityReminder ? .orange : .secondary)
            }
            Spacer(minLength: 0)
        }
        .listRowBackground(
            intro.needsRegularityReminder
                ? Color.orange.opacity(0.10)
                : Color.clear
        )
    }

    private func subtitle(_ intro: AllergenIntroduction) -> String {
        if intro.needsRegularityReminder, let days = intro.daysSinceLastServed {
            return "\(days) gündür verilmedi"
        }
        if intro.status == .notIntroduced { return intro.status.localizedTitle }
        if let days = intro.daysSinceLastServed {
            return days == 0
                ? "\(intro.status.localizedTitle) · bugün"
                : "\(intro.status.localizedTitle) · \(days) gün önce"
        }
        return intro.status.localizedTitle
    }

    private func statusColor(_ status: AllergenStatus) -> Color {
        switch status {
        case .notIntroduced: return .secondary
        case .introduced:    return .orange
        case .tolerated:     return .green
        case .reacted:       return .red
        }
    }
}

/// Tek alerjenin tanıtım rehberi ve kaydı.
struct AllergenDetailView: View {
    @Bindable var introduction: AllergenIntroduction

    @Environment(\.modelContext) private var modelContext

    private var info: AllergenInfo { AllergenCatalog.info(for: introduction.allergen) }

    var body: some View {
        List {
            Section {
                LabeledContent("Durum", value: introduction.status.localizedTitle)
                if let first = introduction.firstTriedAt {
                    LabeledContent("İlk deneme",
                                   value: DateFormatters.displayDate.string(from: first))
                }
                if let last = introduction.lastServedAt {
                    LabeledContent("Son verilme",
                                   value: DateFormatters.displayDate.string(from: last))
                }
            }

            if introduction.needsRegularityReminder, let days = introduction.daysSinceLastServed {
                Section {
                    Label(
                        "\(days) gündür verilmedi",
                        systemImage: "clock.badge.exclamationmark.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                    Text("Tolere edilen alerjenin diyette düzenli tutulması öneriliyor; tek tadım koruyucu etki için yeterli değildir.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Ne zaman ve nasıl") {
                Text(info.introductionGuidance)
                    .font(.footnote)
                Text(info.safeServingForm)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if info.hasStrongEvidence {
                Section {
                    Label("Erken tanıtımın koruyucu etkisi için güçlü kanıt var",
                          systemImage: "checkmark.seal.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }

            Section("İçeren besinler") {
                let foods = FoodCatalog.all.filter { $0.allergen == introduction.allergen }
                ForEach(foods) { food in
                    Text(food.name)
                        .font(.subheadline)
                }
            }

            Section("Not") {
                TextField("Gözlemleriniz", text: Binding(
                    get: { introduction.reactionNotes ?? "" },
                    set: {
                        introduction.reactionNotes = $0.isEmpty ? nil : $0
                        introduction.updatedAt = .now
                        try? modelContext.save()
                    }
                ), axis: .vertical)
                .lineLimit(1...4)
            }

            Section {
                if let url = URL(string: info.sourceURL) {
                    Link("Kaynağı görüntüle", destination: url)
                        .font(.caption)
                }
                Text("Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(introduction.allergen.localizedTitle)
        .inlineNavigationTitle()
    }
}
