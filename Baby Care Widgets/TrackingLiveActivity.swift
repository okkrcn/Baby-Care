import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct TrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrackingActivityAttributes.self) { context in
            TrackingLockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(nil)
        } dynamicIsland: { context in
            let style = TrackingStyle(kind: context.attributes.kind)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(style.title(detail: context.state.detail), systemImage: style.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(style.color)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timer(from: context.state.startedAt)
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .frame(maxWidth: 110, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.babyName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(intent: EndTrackingTimerIntent(
                            recordID: context.attributes.recordID, kind: style.intentKind
                        )) {
                            Label(style.endTitle, systemImage: style.endIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(style.color)
                        .font(.caption.weight(.semibold))
                    }
                }
            } compactLeading: {
                Image(systemName: style.icon)
                    .foregroundStyle(style.color)
            } compactTrailing: {
                timer(from: context.state.startedAt)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(style.color)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: style.icon)
                    .foregroundStyle(style.color)
            }
            .keylineTint(style.color)
        }
    }

    private func timer(from start: Date) -> some View {
        Text(timerInterval: start...Date.distantFuture, countsDown: false)
            .multilineTextAlignment(.trailing)
    }
}

/// Kilit ekranı ve bildirim merkezi görünümü.
struct TrackingLockScreenView: View {
    let attributes: TrackingActivityAttributes
    let state: TrackingActivityAttributes.ContentState

    var body: some View {
        let style = TrackingStyle(kind: attributes.kind)
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(style.color.gradient, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(attributes.babyName) · \(style.name)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(state.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("Başlangıç \(WidgetText.clock(state.startedAt))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(timerInterval: state.startedAt...Date.distantFuture, countsDown: false)
                    .font(.title.weight(.semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 130, alignment: .trailing)
            }

            Button(intent: EndTrackingTimerIntent(recordID: attributes.recordID, kind: style.intentKind)) {
                Label(style.endTitle, systemImage: style.endIcon)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(style.color)
        }
        .padding(16)
    }
}

/// Emzirme ve uyku için ortak görsel dil.
struct TrackingStyle {
    let kind: TrackingActivityAttributes.Kind

    var name: String { kind == .feeding ? "Emzirme" : "Uyku" }
    var icon: String { kind == .feeding ? "drop.fill" : "moon.zzz.fill" }
    var color: Color { kind == .feeding ? WidgetPalette.feeding : WidgetPalette.sleep }
    var endTitle: String { kind == .feeding ? "Bitir" : "Uyandı" }
    var endIcon: String { kind == .feeding ? "stop.fill" : "sun.max.fill" }
    var intentKind: WidgetTimerKind { kind == .feeding ? .feeding : .sleep }

    /// Dynamic Island başlığı: "Emzirme · Sol", "Gündüz uykusu".
    func title(detail: String) -> String {
        guard kind == .feeding else { return detail }
        let side = detail.replacingOccurrences(of: " göğüs", with: "")
        return side == "Emzirme" ? side : "Emzirme · \(side)"
    }
}
