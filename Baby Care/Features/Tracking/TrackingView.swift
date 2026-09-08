import SwiftUI
import SwiftData

struct TrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SelectedBabyStore.self) private var babyStore

    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]
    @Query(sort: \SleepRecord.startedAt, order: .reverse) private var allSleeps: [SleepRecord]
    @Query(sort: \DiaperRecord.recordedAt, order: .reverse) private var allDiapers: [DiaperRecord]
    @Query(sort: \SolidFoodRecord.servedAt, order: .reverse) private var allSolids: [SolidFoodRecord]

    @State private var showFeedingSheet = false
    @State private var showSleepSheet = false
    @State private var showDiaperSheet = false
    @State private var showDiaperDialog = false
    @State private var showFeedingAmount = false
    @State private var feedingAmountText = ""
    @State private var quickError: String?
    @State private var selectedDate: Date = .now

    @State private var editingFeeding: FeedingRecord?
    @State private var editingSleep: SleepRecord?
    @State private var editingDiaper: DiaperRecord?
    @State private var editingSolid: SolidFoodRecord?
    @State private var showSolidSheet = false

    private var baby: Baby? { babyStore.resolved(from: babies) }
    private var babyID: UUID? { baby?.id }

    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) { return "Bugün" }
        if cal.isDateInYesterday(selectedDate) { return "Dün" }
        return DateFormatters.displayDate.string(from: selectedDate)
    }

    private func shiftDay(by days: Int) {
        // Gelecek güne gitmeye izin verme
        if days > 0 && isViewingToday { return }
        if let d = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = min(d, .now)
        }
    }

    private var todaysFeedings: [FeedingRecord] {
        guard let id = babyID else { return [] }
        return allFeedings.filter {
            $0.babyID == id && Calendar.current.isDate($0.startedAt, inSameDayAs: selectedDate)
        }
    }

    private var todaysSleeps: [SleepRecord] {
        guard let id = babyID else { return [] }
        return allSleeps.filter {
            $0.babyID == id && Calendar.current.isDate($0.startedAt, inSameDayAs: selectedDate)
        }
    }

    private var todaysDiapers: [DiaperRecord] {
        guard let id = babyID else { return [] }
        return allDiapers.filter {
            $0.babyID == id && Calendar.current.isDate($0.recordedAt, inSameDayAs: selectedDate)
        }
    }

    private var todaysSolids: [SolidFoodRecord] {
        guard let id = babyID else { return [] }
        return allSolids.filter {
            $0.babyID == id && Calendar.current.isDate($0.servedAt, inSameDayAs: selectedDate)
        }
    }

    /// Ek gıda yüzeyleri yalnız 6 ayını dolduran bebekte görünür.
    private var isSolidAge: Bool {
        baby?.stage.isSolidFoodAge == true
    }

    private var totalFeedingSeconds: Int {
        todaysFeedings.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }
    private var totalBottleML: Int {
        todaysFeedings.reduce(0) { $0 + ($1.amountML ?? 0) }
    }
    /// Beslenme özet alt satırı — biberon ml ve/veya emzirme süresini birleştirir.
    /// (Önceden süre tek başına gösteriliyordu; biberon-only günlerde "0 sn" çıkıyordu.)
    private var feedingSummaryDetail: String {
        var parts: [String] = []
        if totalBottleML > 0 { parts.append("\(totalBottleML) ml") }
        if totalFeedingSeconds > 0 { parts.append(DurationFormatter.string(fromSeconds: totalFeedingSeconds)) }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
    private var totalSleepSeconds: Int {
        todaysSleeps.reduce(0) { $0 + $1.durationSeconds }
    }

    private var ongoingFeeding: FeedingRecord? {
        guard let id = babyID else { return nil }
        return allFeedings.first { $0.babyID == id && $0.isOngoing }
    }

    private var ongoingSleep: SleepRecord? {
        guard let id = babyID else { return nil }
        return allSleeps.first { $0.babyID == id && $0.isOngoing }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if babyID == nil {
                        ContentUnavailableView(
                            "Bebek bilgisi yok",
                            systemImage: "figure.and.child.holdinghands",
                            description: Text("Önce Bebek sekmesinden bir bebek ekleyin.")
                        )
                        .padding(.top, 60)
                    } else {
                        dateNavigator
                        if isViewingToday, ongoingFeeding != nil || ongoingSleep != nil {
                            ongoingSection
                        }
                        summaryRow
                        if isViewingToday {
                            quickAddRow
                        }
                        recentActivitiesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Takip")
            .toolbar {
                if babies.count > 1 {
                    ToolbarItem(placement: .principal) {
                        BabyPickerToolbarMenu(babies: babies, selected: baby)
                    }
                }
                if let baby {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink {
                            WeeklyChartsView(baby: baby)
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                    }
                }
            }
            .sheet(isPresented: $showFeedingSheet) {
                if let id = babyID {
                    FeedingAddSheet(babyID: id)
                }
            }
            .sheet(isPresented: $showSleepSheet) {
                if let id = babyID {
                    SleepAddSheet(babyID: id)
                }
            }
            .sheet(isPresented: $showDiaperSheet) {
                if let id = babyID {
                    DiaperAddSheet(babyID: id)
                }
            }
            .sheet(item: $editingFeeding) { rec in
                if let id = babyID {
                    FeedingAddSheet(babyID: id, editing: rec)
                }
            }
            .sheet(item: $editingSleep) { rec in
                if let id = babyID {
                    SleepAddSheet(babyID: id, editing: rec)
                }
            }
            .sheet(item: $editingDiaper) { rec in
                if let id = babyID {
                    DiaperAddSheet(babyID: id, editing: rec)
                }
            }
            .sheet(isPresented: $showSolidSheet) {
                if let baby {
                    SolidFoodAddSheet(baby: baby)
                }
            }
            .sheet(item: $editingSolid) { rec in
                if let baby {
                    SolidFoodAddSheet(baby: baby, editing: rec)
                }
            }
        }
    }

    // MARK: - Ongoing section (canlı sayaçlar)

    private var ongoingSection: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text("Şu Anda")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    if let f = ongoingFeeding {
                        ongoingCard(
                            icon: "drop.fill",
                            color: .blue,
                            title: "Emzirme",
                            subtitle: f.side?.localizedTitle ?? "—",
                            seconds: max(0, Int(context.date.timeIntervalSince(f.startedAt))),
                            stopAction: { stopFeeding(f) }
                        )
                    }
                    if let s = ongoingSleep {
                        ongoingCard(
                            icon: "moon.zzz.fill",
                            color: .indigo,
                            title: "Uyku",
                            subtitle: s.isNap ? "Gündüz" : "Gece",
                            seconds: max(0, Int(context.date.timeIntervalSince(s.startedAt))),
                            stopAction: { stopSleep(s) }
                        )
                    }
                }
            }
        }
    }

    private func ongoingCard(icon: String, color: Color, title: String, subtitle: String, seconds: Int, stopAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Text(DurationFormatter.string(fromSeconds: seconds))
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(color)

            Button(role: .destructive, action: stopAction) {
                Image(systemName: "stop.circle.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)
            .foregroundStyle(color)
        }
        .padding()
        .background(color.opacity(0.08), in: .rect(cornerRadius: 16))
    }

    private func stopFeeding(_ f: FeedingRecord) {
        guard let baby else { return }
        do {
            try QuickLogService.toggleFeeding(for: baby, ongoing: f, in: modelContext)
            Haptics.success()
        } catch {
            quickError = error.localizedDescription
        }
    }

    private func stopSleep(_ s: SleepRecord) {
        guard let baby else { return }
        do {
            try QuickLogService.toggleSleep(for: baby, ongoing: s, in: modelContext)
            Haptics.success()
        } catch {
            quickError = error.localizedDescription
        }
    }

    // MARK: - Date navigator

    private var dateNavigator: some View {
        HStack {
            Button { shiftDay(by: -1) } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(dayLabel).font(.headline)
                if !isViewingToday {
                    Button("Bugüne dön") { selectedDate = .now }
                        .font(.caption)
                }
            }

            Spacer()

            Button { shiftDay(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(isViewingToday ? .secondary : .primary)
            }
            .buttonStyle(.plain)
            .disabled(isViewingToday)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Summary row

    private var summaryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dayLabel)
                .font(.headline)
                .foregroundStyle(.secondary)

            // 6 ay altında üç kart tek satırda; ek gıda başlayınca 2x2 ızgara.
            if isSolidAge {
                let solid = SolidFoodDaySummary.make(from: todaysSolids)
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        feedingSummaryCard
                        sleepSummaryCard
                    }
                    GridRow {
                        diaperSummaryCard
                        summaryCard(
                            icon: "carrot.fill",
                            color: .brown,
                            title: "Ek Gıda",
                            primary: "\(solid.mealCount) öğün",
                            secondary: solid.detailText
                        )
                    }
                }
            } else {
                HStack(spacing: 12) {
                    feedingSummaryCard
                    sleepSummaryCard
                    diaperSummaryCard
                }
            }
        }
    }

    private var feedingSummaryCard: some View {
        summaryCard(icon: "drop.fill", color: .blue, title: "Beslenme",
                    primary: "\(todaysFeedings.count) öğün", secondary: feedingSummaryDetail)
    }

    private var sleepSummaryCard: some View {
        summaryCard(icon: "moon.zzz.fill", color: .indigo, title: "Uyku",
                    primary: DurationFormatter.string(fromSeconds: totalSleepSeconds),
                    secondary: "\(todaysSleeps.count) kez")
    }

    private var diaperSummaryCard: some View {
        summaryCard(icon: "leaf.fill", color: .green, title: "Bez",
                    primary: "\(todaysDiapers.count)", secondary: "değişim")
    }

    private func summaryCard(icon: String, color: Color, title: String, primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(primary)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(secondary)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
    }

    // MARK: - Quick add

    private var quickAddRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Hızlı Ekle")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Detay için basılı tutun")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                quickButton(
                    title: "Beslenme",
                    icon: "drop.fill",
                    color: .blue,
                    isActive: false,
                    tap: { feedingAmountText = ""; showFeedingAmount = true },
                    long: { showFeedingSheet = true }
                )
                quickButton(
                    title: ongoingSleep == nil ? "Uyku" : "Uyku Sürüyor",
                    icon: ongoingSleep == nil ? "moon.zzz.fill" : "moon.zzz",
                    color: .indigo,
                    isActive: ongoingSleep != nil,
                    tap: { quickSleep() },
                    long: { showSleepSheet = true }
                )
                quickButton(
                    title: "Bez",
                    icon: "leaf.fill",
                    color: .green,
                    isActive: false,
                    tap: { showDiaperDialog = true },
                    long: { showDiaperSheet = true }
                )
                if isSolidAge {
                    quickButton(
                        title: "Ek Gıda",
                        icon: "carrot.fill",
                        color: .brown,
                        isActive: false,
                        tap: { showSolidSheet = true },
                        long: { showSolidSheet = true }
                    )
                }
            }
        }
        .confirmationDialog("Bez Değişimi", isPresented: $showDiaperDialog, titleVisibility: .visible) {
            Button("Çiş") { quickDiaper(.pee) }
            Button("Kaka") { quickDiaper(.poo) }
            Button("Karışık") { quickDiaper(.both) }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Detaylı kayıt (kıvam, saat, not) için butonu basılı tutun.")
        }
        .alert("Kaç CC içti?", isPresented: $showFeedingAmount) {
            TextField("Örn: 90", text: $feedingAmountText)
                .numericKeyboard()
            Button("Sağılmış süt") { saveFeedingAmount(.bottleBreastmilk) }
            Button("Mama") { saveFeedingAmount(.bottleFormula) }
            Button("Vazgeç", role: .cancel) { feedingAmountText = "" }
        } message: {
            Text("Miktarı yazıp süt türünü seçin. Süreli emzirme için butonu basılı tutun.")
        }
        .alert("Kaydedilemedi", isPresented: Binding(get: { quickError != nil }, set: { if !$0 { quickError = nil } })) {
            Button("Tamam", role: .cancel) { quickError = nil }
        } message: {
            Text(quickError ?? "")
        }
    }

    private func quickButton(
        title: String,
        icon: String,
        color: Color,
        isActive: Bool,
        tap: @escaping () -> Void,
        long: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isActive ? .white : color)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isActive ? .white : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            isActive ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.12)),
            in: .rect(cornerRadius: 14)
        )
        .contentShape(.rect)
        .onTapGesture { tap() }
        .onLongPressGesture(minimumDuration: 0.5) { long() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Dokun: hızlı kaydet. Basılı tut: detaylı ekle.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Quick add actions

    private func saveFeedingAmount(_ type: FeedingType) {
        guard let baby else { return }
        guard let ml = Int(feedingAmountText.trimmingCharacters(in: .whitespaces)), ml > 0 else {
            quickError = "Geçerli bir CC miktarı girin."
            return
        }
        do {
            try QuickLogService.logBottle(type, amountML: ml, for: baby, in: modelContext)
            Haptics.success()
            feedingAmountText = ""
        } catch {
            quickError = error.localizedDescription
        }
    }

    private func quickSleep() {
        guard let baby else { return }
        do {
            try QuickLogService.toggleSleep(for: baby, ongoing: ongoingSleep, in: modelContext)
            Haptics.success()
        } catch {
            quickError = error.localizedDescription
        }
    }

    private func quickDiaper(_ type: DiaperType) {
        guard let baby else { return }
        do {
            try QuickLogService.logDiaper(type, for: baby, in: modelContext)
            Haptics.success()
        } catch {
            quickError = error.localizedDescription
        }
    }

    // MARK: - Recent activities

    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Son Aktiviteler")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Düzenlemek için basılı tutun")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            let activities = mergedRecentActivities(limit: 15)

            if activities.isEmpty {
                Text("Henüz kayıt yok. Yukarıdan hızlıca ekleyebilirsiniz.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: 14))
            } else {
                VStack(spacing: 8) {
                    ForEach(activities, id: \.id) { item in
                        activityRow(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .foregroundStyle(item.color)
                .frame(width: 32, height: 32)
                .background(item.color.opacity(0.15), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(DateFormatters.displayTime.string(from: item.timestamp))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .contextMenu {
            Button {
                openEdit(for: item.kind)
            } label: {
                Label("Düzenle", systemImage: "pencil")
            }
            Button(role: .destructive) {
                delete(item.kind)
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    private func openEdit(for kind: ActivityKind) {
        switch kind {
        case .feeding(let f): editingFeeding = f
        case .sleep(let s):   editingSleep = s
        case .diaper(let d):  editingDiaper = d
        case .solid(let s):   editingSolid = s
        }
    }

    private func delete(_ kind: ActivityKind) {
        switch kind {
        case .feeding(let f): modelContext.delete(f)
        case .sleep(let s):   modelContext.delete(s)
        case .diaper(let d):  modelContext.delete(d)
        case .solid(let s):   modelContext.delete(s)
        }
        try? modelContext.save()
    }

    // MARK: - Activity merging

    private enum ActivityKind {
        case feeding(FeedingRecord)
        case sleep(SleepRecord)
        case diaper(DiaperRecord)
        case solid(SolidFoodRecord)
    }

    private struct ActivityItem {
        let id: UUID
        let timestamp: Date
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let kind: ActivityKind
    }

    private func mergedRecentActivities(limit: Int) -> [ActivityItem] {
        var items: [ActivityItem] = []

        // todaysFeedings/Sleeps/Diapers seçili güne göre filtrelidir.
        for f in todaysFeedings {
            let sub: String
            if let dur = f.durationSeconds {
                sub = "\(f.type.localizedTitle) · \(DurationFormatter.string(fromSeconds: dur))"
            } else if let ml = f.amountML {
                sub = "\(f.type.localizedTitle) · \(ml) ml"
            } else {
                sub = f.type.localizedTitle
            }
            items.append(.init(
                id: f.id, timestamp: f.startedAt,
                title: "Beslenme", subtitle: sub,
                icon: f.type.icon, color: .blue,
                kind: .feeding(f)
            ))
        }

        for s in todaysSleeps {
            let sub: String
            if s.isOngoing {
                sub = "Devam ediyor"
            } else {
                sub = "\(s.isNap ? "Gündüz" : "Gece") · \(DurationFormatter.string(fromSeconds: s.durationSeconds))"
            }
            items.append(.init(
                id: s.id, timestamp: s.startedAt,
                title: "Uyku", subtitle: sub,
                icon: "moon.zzz.fill", color: .indigo,
                kind: .sleep(s)
            ))
        }

        for d in todaysDiapers {
            items.append(.init(
                id: d.id, timestamp: d.recordedAt,
                title: "Bez", subtitle: d.type.localizedTitle,
                icon: d.type.icon, color: .green,
                kind: .diaper(d)
            ))
        }

        for s in todaysSolids {
            var parts = [s.method.localizedTitle, s.amount.localizedTitle]
            if s.isFirstTry { parts.append("Yeni besin") }
            items.append(.init(
                id: s.id, timestamp: s.servedAt,
                title: s.displayName, subtitle: parts.joined(separator: " · "),
                icon: "carrot.fill", color: .brown,
                kind: .solid(s)
            ))
        }

        return items.sorted { $0.timestamp > $1.timestamp }
    }
}
