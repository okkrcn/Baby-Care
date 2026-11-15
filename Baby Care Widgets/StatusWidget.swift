import AppIntents
import SwiftUI
import WidgetKit

struct StatusEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

/// Süreler dakika hassasiyetinde "2 sa 15 dk" biçiminde gösterilir. Sistemin
/// göreli tarih biçimi uygulama dilinden bağımsız İngilizce çıkabildiği için
/// metin her girdide önceden hesaplanır.
struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(StatusEntry(date: .now, snapshot: WidgetSnapshotStore.load() ?? (context.isPreview ? .preview : nil)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        let start = Calendar.current.dateInterval(of: .minute, for: .now)?.start ?? .now
        var dates: [Date] = []
        // İlk 90 dakika her dakika, sonra 12 saate kadar 5 dakikada bir.
        for minute in 0..<90 { dates.append(start.addingTimeInterval(Double(minute) * 60)) }
        for step in stride(from: 90, through: 720, by: 5) { dates.append(start.addingTimeInterval(Double(step) * 60)) }
        let entries = dates.map { StatusEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct StatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BabyCareStatus", provider: StatusProvider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Son kayıtlar")
        .description("Son beslenme, uyku ve bez değişiminin üzerinden geçen süre.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct StatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StatusEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .systemMedium: MediumStatusView(snapshot: snapshot, now: entry.date)
                case .accessoryRectangular: RectangularStatusView(snapshot: snapshot, now: entry.date)
                case .accessoryCircular: CircularStatusView(snapshot: snapshot, now: entry.date)
                default: SmallStatusView(snapshot: snapshot, now: entry.date)
                }
            } else {
                EmptyStatusView(family: family)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Küçük

private struct SmallStatusView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let ongoing = snapshot.ongoingFeeding {
                Label("Emzirme sürüyor", systemImage: "drop.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.feeding)
                Text(timerInterval: ongoing.startedAt...Date.distantFuture, countsDown: false)
                    .font(.title2.weight(.semibold).monospacedDigit())
                Text(ongoing.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("Son beslenme", systemImage: "drop.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.feeding)
                if let last = snapshot.lastFeedingAt {
                    Text(WidgetText.elapsed(since: last, now: now))
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    if let detail = snapshot.lastFeedingDetail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    Text("Kayıt yok")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
            Divider()
            Label {
                Text(snapshot.lastDiaperAt.map { "Bez · \(WidgetText.ago($0, now: now))" } ?? "Bez · kayıt yok")
            } icon: {
                Image(systemName: "leaf.fill")
            }
            .font(.caption)
            .foregroundStyle(WidgetPalette.diaper)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Orta

private struct MediumStatusView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(snapshot.babyName) · \(snapshot.ageText)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                tile(
                    title: "Beslenme", icon: "drop.fill", color: WidgetPalette.feeding,
                    ongoing: snapshot.ongoingFeeding, last: snapshot.lastFeedingAt
                ) {
                    Button(intent: ToggleFeedingWidgetIntent()) {
                        Text(snapshot.ongoingFeeding == nil ? "Emzir" : "Bitir")
                    }
                    .tint(WidgetPalette.feeding)
                }

                tile(
                    title: "Uyku", icon: "moon.zzz.fill", color: WidgetPalette.sleep,
                    ongoing: snapshot.ongoingSleep, last: snapshot.lastSleepEndedAt
                ) {
                    Button(intent: ToggleSleepWidgetIntent()) {
                        Text(snapshot.ongoingSleep == nil ? "Uyut" : "Uyandı")
                    }
                    .tint(WidgetPalette.sleep)
                }

                tile(
                    title: "Bez", icon: "leaf.fill", color: WidgetPalette.diaper,
                    ongoing: nil, last: snapshot.lastDiaperAt
                ) {
                    // Dar kutuda iki düğme sığsın diye metinler tek satıra sabitlenir.
                    HStack(spacing: 3) {
                        Button(intent: LogDiaperWidgetIntent(kind: .pee)) { Text("Çiş").lineLimit(1).fixedSize() }
                        Button(intent: LogDiaperWidgetIntent(kind: .poo)) { Text("Kaka").lineLimit(1).fixedSize() }
                    }
                    .tint(WidgetPalette.diaper)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
        }
    }

    @ViewBuilder
    private func tile<Actions: View>(
        title: String,
        icon: String,
        color: Color,
        ongoing: WidgetSnapshot.Ongoing?,
        last: Date?,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)

            Group {
                if let ongoing {
                    Text(timerInterval: ongoing.startedAt...Date.distantFuture, countsDown: false)
                } else if let last {
                    Text(WidgetText.ago(last, now: now))
                } else {
                    Text("Kayıt yok").foregroundStyle(.secondary)
                }
            }
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Spacer(minLength: 0)
            actions()
                .font(.caption2.weight(.semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.14), in: .rect(cornerRadius: 12))
    }
}

// MARK: - Kilit ekranı

private struct RectangularStatusView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let ongoing = snapshot.ongoingFeeding {
                Label("Emzirme sürüyor", systemImage: "drop.fill")
                    .font(.caption2)
                Text(timerInterval: ongoing.startedAt...Date.distantFuture, countsDown: false)
                    .font(.headline.monospacedDigit())
            } else if let last = snapshot.lastFeedingAt {
                Label("Son beslenme \(WidgetText.clock(last))", systemImage: "drop.fill")
                    .font(.caption2)
                Text(WidgetText.ago(last, now: now))
                    .font(.headline.monospacedDigit())
            } else {
                Label("Son beslenme", systemImage: "drop.fill")
                    .font(.caption2)
                Text("Kayıt yok")
                    .font(.headline)
            }
            Text(secondaryLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var secondaryLine: String {
        var parts: [String] = []
        if let diaper = snapshot.lastDiaperAt { parts.append("Bez \(WidgetText.elapsed(since: diaper, now: now))") }
        if snapshot.ongoingSleep != nil {
            parts.append("Uyuyor")
        } else if let sleep = snapshot.lastSleepEndedAt {
            parts.append("Uyku \(WidgetText.elapsed(since: sleep, now: now))")
        }
        return parts.isEmpty ? snapshot.babyName : parts.joined(separator: " · ")
    }
}

private struct CircularStatusView: View {
    let snapshot: WidgetSnapshot
    let now: Date

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "drop.fill")
                    .font(.caption)
                if snapshot.ongoingFeeding != nil {
                    Text("Sürüyor")
                        .font(.system(size: 10, weight: .semibold))
                } else if let last = snapshot.lastFeedingAt {
                    Text(WidgetText.compact(since: last, now: now))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                } else {
                    Text("—")
                        .font(.caption)
                }
            }
            .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Boş durum

private struct EmptyStatusView: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "figure.and.child.holdinghands")
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("Baby Care").font(.headline)
                Text("Bebek profili ekleyin").font(.caption2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.title2)
                    .foregroundStyle(.pink)
                Text("Bebek profili ekleyin")
                    .font(.subheadline.weight(.semibold))
                Text("Kayıtlar burada görünür.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

extension WidgetSnapshot {
    /// Widget galerisinde gösterilen örnek veri.
    static var preview: WidgetSnapshot {
        let now = Date()
        return WidgetSnapshot(
            babyName: "Bebeğim",
            ageText: "4 aylık",
            lastFeedingAt: now.addingTimeInterval(-135 * 60),
            lastFeedingDetail: "Mama · 90 ml",
            ongoingFeeding: nil,
            lastSleepEndedAt: now.addingTimeInterval(-55 * 60),
            ongoingSleep: nil,
            lastDiaperAt: now.addingTimeInterval(-40 * 60),
            lastDiaperType: "Çiş",
            generatedAt: now
        )
    }
}
