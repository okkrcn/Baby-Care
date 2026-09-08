import SwiftUI

/// Besin kütüphanesi. İki modda çalışır:
///  - Gezinme modu (`selection == nil`): satıra dokununca besin kartı açılır.
///  - Seçim modu: öğün formundan gelinir, çoklu seçim yapılır.
struct FoodLibraryView: View {
    let baby: Baby
    var selection: Binding<Set<String>>?

    @State private var query = ""
    @State private var group: FoodGroup?
    @State private var onlyAgeAppropriate = true

    private var isSelecting: Bool { selection != nil }

    private var results: [FoodItem] {
        var items = onlyAgeAppropriate
            ? FoodCatalog.items(forAgeMonths: baby.ageInMonths)
            : FoodCatalog.all
        if let group {
            items = items.filter { $0.group == group }
        }
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            let matches = Set(FoodCatalog.search(query).map(\.id))
            items = items.filter { matches.contains($0.id) }
        }
        return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                Toggle("Yalnız yaşına uygun besinler", isOn: $onlyAgeAppropriate)
                    .font(.subheadline)
                groupPicker
            }

            if results.isEmpty {
                Section {
                    ContentUnavailableView(
                        "Besin bulunamadı",
                        systemImage: "magnifyingglass",
                        description: Text(emptyDescription)
                    )
                }
            } else {
                Section {
                    ForEach(results) { item in
                        row(item)
                    }
                } header: {
                    Text("\(results.count) besin")
                }
            }
        }
        .searchable(text: $query, prompt: "Besin ara")
        .navigationTitle(isSelecting ? "Besin Seç" : "Besinler")
        .inlineNavigationTitle()
    }

    private var emptyDescription: String {
        if onlyAgeAppropriate {
            return "Aramanızla eşleşen besin yok. Yaş filtresini kapatarak tüm kütüphaneyi görebilirsiniz."
        }
        return "Aramanızla eşleşen besin yok. Farklı bir kelime deneyin."
    }

    private var groupPicker: some View {
        Picker("Grup", selection: $group) {
            Text("Tümü").tag(FoodGroup?.none)
            ForEach(FoodGroup.allCases, id: \.self) { g in
                Text(g.localizedTitle).tag(FoodGroup?.some(g))
            }
        }
        .pickerStyle(.menu)
        .font(.subheadline)
    }

    @ViewBuilder
    private func row(_ item: FoodItem) -> some View {
        if let selection {
            Button {
                toggle(item.id, in: selection)
            } label: {
                HStack(spacing: 10) {
                    rowContent(item)
                    Spacer(minLength: 0)
                    Image(systemName: selection.wrappedValue.contains(item.id)
                          ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selection.wrappedValue.contains(item.id) ? .brown : .secondary)
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                FoodDetailView(item: item, baby: baby)
            } label: {
                rowContent(item)
            }
        }
    }

    private func rowContent(_ item: FoodItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.group.icon)
                .font(.footnote)
                .foregroundStyle(.brown)
                .frame(width: 28, height: 28)
                .background(.brown.opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text(item.group.localizedTitle)
                    if item.isIronRich { Text("· Demir") }
                    if item.allergen != nil { Text("· Alerjen") }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if item.chokingRisk == .high {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Yüksek boğulma riski")
            }
        }
    }

    private func toggle(_ id: String, in selection: Binding<Set<String>>) {
        if selection.wrappedValue.contains(id) {
            selection.wrappedValue.remove(id)
        } else {
            selection.wrappedValue.insert(id)
        }
    }
}
