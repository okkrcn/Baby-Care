import SwiftUI
import SwiftData

enum TeethPalette {
    static let accent = Color.teal
}

/// Süt dişi haritası: çıkan dişleri işaretleme ve tipik çıkış dönemleri.
/// Tanı koymaz; aralıklar yalnızca bilgi amaçlıdır.
struct TeethView: View {
    let baby: Baby

    @Query(sort: \ToothEruption.eruptedAt) private var allEruptions: [ToothEruption]
    @State private var editingTooth: PrimaryTooth?

    private var eruptions: [ToothEruption] {
        allEruptions.filter { $0.babyID == baby.id }
    }

    private var eruptedIDs: Set<String> { Set(eruptions.map(\.toothID)) }

    var body: some View {
        List {
            Section {
                summaryRow
            }

            Section {
                ToothArchView(
                    eruptedIDs: eruptedIDs,
                    ageInMonths: baby.ageInMonths,
                    onSelect: { editingTooth = $0 }
                )
                .padding(.vertical, 4)
                legend
            } header: {
                Text("Diş haritası")
            } footer: {
                Text("Çıkan dişe dokunarak tarihini kaydedin. Harita bebeğe karşıdan bakılmış gibidir.")
            }

            let upcoming = TeethCatalog.upcoming(erupted: eruptedIDs)
            if !upcoming.isEmpty {
                Section("Sıradaki tipik dişler") {
                    ForEach(Array(upcoming.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text("\(item.jaw.localizedTitle) \(item.kind.pluralTitle)")
                            Spacer()
                            Text("genellikle \(item.months.lowerBound)–\(item.months.upperBound) ay")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }

            Section("Bilmekte yarar var") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("İlk diş çıktığında ya da en geç 1 yaşında ilk diş hekimi kontrolü önerilir.")
                    Text("Diş çıkışı bebekten bebeğe aylarca farklılık gösterebilir. Endişe duyarsanız diş hekiminize danışın.")
                        .foregroundStyle(.secondary)
                    Link("Kaynağı görüntüle", destination: TeethCatalog.firstVisitSourceURL)
                }
                .font(.subheadline)
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Diş çıkarma ağrısı için benzokain veya lidokain içeren jeller ve kehribar kolye gibi takılar önerilmez.")
                    Text("Buzdolabında soğutulmuş (dondurulmamış) diş kaşıyıcı ve temiz parmakla diş etine hafif masaj önerilen yöntemlerdir.")
                        .foregroundStyle(.secondary)
                    Link("Kaynağı görüntüle", destination: TeethCatalog.teethingSafetySourceURL)
                }
                .font(.subheadline)
                .padding(.vertical, 2)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz. Çıkış aralıkları \(TeethCatalog.sourceTitle) süt dişi tablosuna dayanır.")
                    Link("Kaynağı görüntüle", destination: TeethCatalog.sourceURL)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Diş Gelişimi")
        .sheet(item: $editingTooth) { tooth in
            ToothEditSheet(
                baby: baby,
                tooth: tooth,
                existing: eruptions.first { $0.toothID == tooth.id }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 14) {
            Text("\(eruptions.count)/20")
                .font(.headline.monospacedDigit())
                .foregroundStyle(TeethPalette.accent)
                .frame(width: 58, height: 58)
                .background(TeethPalette.accent.opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                if let last = eruptions.max(by: { $0.eruptedAt < $1.eruptedAt }), let tooth = last.tooth {
                    Text("\(eruptions.count) süt dişi çıktı")
                        .font(.headline)
                    Text("Son: \(tooth.name) · \(Self.dayMonth.string(from: last.eruptedAt))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Henüz diş işaretlenmedi")
                        .font(.headline)
                    Text("Çoğu bebekte ilk diş 6 ay civarında çıkar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem("Çıktı") {
                RoundedRectangle(cornerRadius: 3).fill(TeethPalette.accent)
            }
            legendItem("Bu aylarda tipik") {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(TeethPalette.accent, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            }
            legendItem("Henüz değil") {
                RoundedRectangle(cornerRadius: 3).strokeBorder(Color(.tertiaryLabel), lineWidth: 1.5)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    private func legendItem<S: View>(_ title: String, @ViewBuilder swatch: () -> S) -> some View {
        HStack(spacing: 5) {
            swatch().frame(width: 11, height: 11)
            Text(title)
        }
    }

    private static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM"
        return f
    }()
}

// MARK: - Harita

/// Üst ve alt çeneyi iki yay üzerinde çizer. Koordinatlar 300×250'lik bir
/// alanda hesaplanır ve mevcut genişliğe ölçeklenir.
struct ToothArchView: View {
    let eruptedIDs: Set<String>
    let ageInMonths: Int
    let onSelect: (PrimaryTooth) -> Void

    private static let canvas = CGSize(width: 300, height: 250)
    private static let angles: [ToothKind: Double] = [
        .centralIncisor: 6, .lateralIncisor: 18, .canine: 31, .firstMolar: 47, .secondMolar: 68,
    ]
    private static let sizes: [ToothKind: CGFloat] = [
        .centralIncisor: 22, .lateralIncisor: 18, .canine: 17, .firstMolar: 24, .secondMolar: 26,
    ]

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Self.canvas.width
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 40 * scale, y: 124 * scale))
                    path.addLine(to: CGPoint(x: 260 * scale, y: 124 * scale))
                }
                .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                Text("Üst çene")
                    .position(x: 150 * scale, y: 96 * scale)
                Text("Alt çene")
                    .position(x: 150 * scale, y: 152 * scale)
                Text("Sağ")
                    .position(x: 18 * scale, y: 124 * scale)
                Text("Sol")
                    .position(x: 282 * scale, y: 124 * scale)

                ForEach(PrimaryTooth.all) { tooth in
                    let layout = Self.layout(for: tooth)
                    ToothShape(state: state(for: tooth), isMolar: tooth.kind.isMolar)
                        .frame(width: layout.size * scale, height: layout.size * scale)
                        .rotationEffect(.degrees(layout.rotation))
                        .position(x: layout.center.x * scale, y: layout.center.y * scale)
                        .accessibilityElement()
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(tooth.name)
                        .accessibilityValue(accessibilityValue(for: tooth))
                        .accessibilityIdentifier("tooth.\(tooth.id)")
                        .accessibilityAction { onSelect(tooth) }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            // Dişler 44 pt'den küçük ve birbirine yakın; tek dokunma alanı en
            // yakın dişi seçer, böylece komşu dişin üstüne basılmaz.
            .contentShape(Rectangle())
            .onTapGesture { location in
                if let tooth = Self.nearestTooth(to: location, scale: scale) {
                    onSelect(tooth)
                }
            }
        }
        .aspectRatio(Self.canvas.width / Self.canvas.height, contentMode: .fit)
    }

    private func state(for tooth: PrimaryTooth) -> ToothShape.State {
        if eruptedIDs.contains(tooth.id) { return .erupted }
        if TeethCatalog.isInTypicalWindow(tooth, ageInMonths: ageInMonths, erupted: eruptedIDs) { return .typical }
        return .pending
    }

    private func accessibilityValue(for tooth: PrimaryTooth) -> String {
        switch state(for: tooth) {
        case .erupted: return "Çıktı"
        case .typical: return "Henüz işaretlenmedi, \(tooth.typicalRangeText)"
        case .pending: return "Henüz işaretlenmedi"
        }
    }

    static func nearestTooth(to point: CGPoint, scale: CGFloat) -> PrimaryTooth? {
        let candidates = PrimaryTooth.all.map { tooth -> (PrimaryTooth, CGFloat) in
            let c = layout(for: tooth).center
            return (tooth, hypot(c.x * scale - point.x, c.y * scale - point.y))
        }
        guard let best = candidates.min(by: { $0.1 < $1.1 }), best.1 <= 32 else { return nil }
        return best.0
    }

    static func layout(for tooth: PrimaryTooth) -> (center: CGPoint, size: CGFloat, rotation: Double) {
        let degrees = angles[tooth.kind] ?? 0
        // Bebeğin sağı ekranın solundadır.
        let signed = tooth.side == .right ? -degrees : degrees
        let radians = signed * .pi / 180
        let x = 150 + 108 * sin(radians)
        let isUpper = tooth.jaw == .upper
        let y = isUpper ? 124 - 96 * cos(radians) + 8 : 124 + 96 * cos(radians) - 8
        return (CGPoint(x: x, y: y), sizes[tooth.kind] ?? 20, isUpper ? signed : -signed)
    }
}

struct ToothShape: View {
    enum State { case erupted, typical, pending }

    let state: State
    let isMolar: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: isMolar ? 8 : 6, style: .continuous)
        switch state {
        case .erupted:
            shape.fill(TeethPalette.accent)
        case .typical:
            shape.fill(TeethPalette.accent.opacity(0.12))
                .overlay(shape.strokeBorder(TeethPalette.accent, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])))
        case .pending:
            shape.fill(Color(.secondarySystemGroupedBackground))
                .overlay(shape.strokeBorder(Color(.tertiaryLabel), lineWidth: 1.5))
        }
    }
}

// MARK: - Düzenleme

struct ToothEditSheet: View {
    let baby: Baby
    let tooth: PrimaryTooth
    let existing: ToothEruption?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isErupted: Bool
    @State private var eruptedAt: Date
    @State private var notes: String
    @State private var errorMessage: String?

    init(baby: Baby, tooth: PrimaryTooth, existing: ToothEruption?) {
        self.baby = baby
        self.tooth = tooth
        self.existing = existing
        // Dişe dokunmak çoğunlukla "çıktı" demektir; varsayılan açık.
        _isErupted = State(initialValue: true)
        _eruptedAt = State(initialValue: existing?.eruptedAt ?? .now)
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tooth.name).font(.headline)
                        Text("Genellikle \(tooth.typicalMonths.lowerBound)–\(tooth.typicalMonths.upperBound) ayda çıkar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle("Çıktı", isOn: $isErupted)
                        .tint(TeethPalette.accent)
                    if isErupted {
                        DatePicker(
                            "Çıktığı tarih",
                            selection: $eruptedAt,
                            in: baby.birthDate...Date.now,
                            displayedComponents: .date
                        )
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                        TextField("Not (isteğe bağlı)", text: $notes, axis: .vertical)
                    }
                } footer: {
                    if existing != nil && !isErupted {
                        Text("Kaydettiğinizde bu dişin kaydı silinir.")
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Diş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                }
            }
        }
    }

    private func save() {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if isErupted {
            if let existing {
                existing.eruptedAt = eruptedAt
                existing.notes = trimmed.isEmpty ? nil : trimmed
                existing.updatedAt = .now
            } else {
                modelContext.insert(ToothEruption(
                    babyID: baby.id,
                    toothID: tooth.id,
                    eruptedAt: eruptedAt,
                    notes: trimmed.isEmpty ? nil : trimmed
                ))
            }
        } else if let existing {
            modelContext.delete(existing)
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Kaydedilemedi. Tekrar deneyin."
        }
    }
}
