import SwiftUI
import SwiftData

/// Ek Gıda ana ekranı: yaşa göre rehber, besin kütüphanesi ve alerjen paneli.
struct SolidFoodView: View {
    let baby: Baby

    private enum Tab: String, CaseIterable {
        case guide = "Rehber"
        case foods = "Besinler"
        case allergens = "Alerjenler"
    }

    @State private var tab: Tab = .guide

    private var stage: GuideStage {
        GuideCatalog.stage(forAgeWeeks: baby.ageInWeeks)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Bölüm", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            switch tab {
            case .guide:     guideList
            case .foods:     FoodLibraryView(baby: baby)
            case .allergens: AllergenPanelView(baby: baby)
            }
        }
        .navigationTitle("Ek Gıda")
        .inlineNavigationTitle()
    }

    // MARK: - Rehber

    private var guideList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.title)
                        .font(.headline)
                    Text(stage.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section("Bu dönemde") {
                ForEach(stage.feedingTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(.brown)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(tip)
                            .font(.subheadline)
                    }
                }
            }

            Section {
                ForEach(barredNow) { item in
                    if let barrier = item.ageBarrier {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(barrier.minAgeMonths) aydan önce verilmez")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.vertical, 1)
                    }
                }
            } header: {
                Label("Bu yaşta verilmez", systemImage: "exclamationmark.octagon.fill")
                    .foregroundStyle(.red)
            }

            Section {
                NavigationLink {
                    FirstAidDetailView(scenario: chokingScenario)
                } label: {
                    Label("Boğulma durumunda ne yapmalı", systemImage: "lungs.fill")
                        .foregroundStyle(.red)
                }
                NavigationLink {
                    SymptomDetailView(category: SymptomCatalog.alerjikReaksiyon)
                } label: {
                    Label("Alerjik reaksiyon belirtileri", systemImage: "allergens.fill")
                        .foregroundStyle(.pink)
                }
            } header: {
                Text("Güvenlik")
            }

            Section {
                Text("İçerik [TÜBER 2022](https://hsgm.saglik.gov.tr/depo/birimler/saglikli-beslenme-ve-hareketli-hayat-db/Dokumanlar/Rehberler/Turkiye_Beslenme_Rehber_TUBER_2022_min.pdf) ve [DSÖ tamamlayıcı beslenme kılavuzuna](https://www.who.int/health-topics/complementary-feeding) dayanır. Bilgilendirme amaçlıdır; her bebek farklı ilerler. Endişe duyduğunuzda pediatristinize danışın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Bebeğin yaşında henüz verilmemesi gereken besinler.
    private var barredNow: [FoodItem] {
        FoodCatalog.all.filter { item in
            guard let barrier = item.ageBarrier else { return false }
            return baby.ageInMonths < barrier.minAgeMonths
        }
    }

    /// Bebeğin yaşına uygun boğulma senaryosu.
    private var chokingScenario: FirstAidScenario {
        let id = baby.ageInMonths >= 12 ? "choking_toddler" : "choking"
        return FirstAidCatalog.scenarios.first { $0.id == id } ?? FirstAidCatalog.choking
    }
}
