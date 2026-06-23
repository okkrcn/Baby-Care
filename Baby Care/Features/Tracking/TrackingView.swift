import SwiftUI
import SwiftData

struct TrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SelectedBabyStore.self) private var babyStore

    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]
    @Query(sort: \SleepRecord.startedAt, order: .reverse) private var allSleeps: [SleepRecord]
    @Query(sort: \DiaperRecord.recordedAt, order: .reverse) private var allDiapers: [DiaperRecord]

    @State private var showFeedingSheet = false
    @State private var showSleepSheet = false
    @State private var showDiaperSheet = false

    @State private var editingFeeding: FeedingRecord?
    @State private var editingSleep: SleepRecord?
    @State private var editingDiaper: DiaperRecord?

    private var baby: Baby? { babyStore.resolved(from: babies) }
    private var babyID: UUID? { baby?.id }

    private var todaysFeedings: [FeedingRecord] {
        guard let id = babyID else { return [] }
        return allFeedings.filter {
            $0.babyID == id && Calendar.current.isDateInToday($0.startedAt)
        }
    }

    private var todaysSleeps: [SleepRecord] {
        guard let id = babyID else { return [] }
        return allSleeps.filter {
            $0.babyID == id && Calendar.current.isDateInToday($0.startedAt)
        }
    }

    private var todaysDiapers: [DiaperRecord] {
        guard let id = babyID else { return [] }
        return allDiapers.filter {
            $0.babyID == id && Calendar.current.isDateInToday($0.recordedAt)
        }
    }

    private var totalFeedingSeconds: Int {
        todaysFeedings.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }
    private var totalBottleML: Int {
        todaysFeedings.reduce(0) { $0 + ($1.amountML ?? 0) }
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
                        if ongoingFeeding != nil || ongoingSleep != nil {
                            ongoingSection
                        }
                        summaryRow
                        quickAddRow
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
        let now = Date()
        f.endedAt = now
        f.durationSeconds = max(1, Int(now.timeIntervalSince(f.startedAt)))
        f.updatedAt = now
        try? modelContext.save()
    }

    private func stopSleep(_ s: SleepRecord) {
        let now = Date()
        s.endedAt = now
        s.updatedAt = now
        try? modelContext.save()
    }

    // MARK: - Summary row

    private var summaryRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bugün")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                summaryCard(
                    icon: "drop.fill",
                    color: .blue,
                    title: "Beslenme",
                    primary: DurationFormatter.string(fromSeconds: totalFeedingSeconds),
                    secondary: totalBottleML > 0 ? "+ \(totalBottleML) ml" : "\(todaysFeedings.count) öğün"
                )
                summaryCard(
                    icon: "moon.zzz.fill",
                    color: .indigo,
                    title: "Uyku",
                    primary: DurationFormatter.string(fromSeconds: totalSleepSeconds),
                    secondary: "\(todaysSleeps.count) kez"
                )
                summaryCard(
                    icon: "leaf.fill",
                    color: .green,
                    title: "Bez",
                    primary: "\(todaysDiapers.count)",
                    secondary: "değişim"
                )
            }
        }
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
            Text("Hızlı Ekle")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                quickButton(title: "Beslenme", icon: "drop.fill", color: .blue) {
                    showFeedingSheet = true
                }
                quickButton(title: "Uyku", icon: "moon.zzz.fill", color: .indigo) {
                    showSleepSheet = true
                }
                quickButton(title: "Bez", icon: "leaf.fill", color: .green) {
                    showDiaperSheet = true
                }
            }
        }
    }

    private func quickButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
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
        }
    }

    private func delete(_ kind: ActivityKind) {
        switch kind {
        case .feeding(let f): modelContext.delete(f)
        case .sleep(let s):   modelContext.delete(s)
        case .diaper(let d):  modelContext.delete(d)
        }
        try? modelContext.save()
    }

    // MARK: - Activity merging

    private enum ActivityKind {
        case feeding(FeedingRecord)
        case sleep(SleepRecord)
        case diaper(DiaperRecord)
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
        guard let id = babyID else { return [] }

        var items: [ActivityItem] = []

        for f in allFeedings.filter({ $0.babyID == id }).prefix(limit) {
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

        for s in allSleeps.filter({ $0.babyID == id }).prefix(limit) {
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

        for d in allDiapers.filter({ $0.babyID == id }).prefix(limit) {
            items.append(.init(
                id: d.id, timestamp: d.recordedAt,
                title: "Bez", subtitle: d.type.localizedTitle,
                icon: d.type.icon, color: .green,
                kind: .diaper(d)
            ))
        }

        return items
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
}
