import SwiftUI

struct SymptomDetailView: View {
    let category: SymptomCategory

    @State private var selectedScenario: SymptomScenario?

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title)
                        .foregroundStyle(category.color)
                        .frame(width: 50, height: 50)
                        .background(category.color.opacity(0.15), in: .circle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.title3.bold())
                        Text(category.prompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Durumu Seçin") {
                ForEach(category.scenarios) { scenario in
                    Button {
                        selectedScenario = scenario
                    } label: {
                        scenarioRow(scenario)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                NavigationLink {
                    EmergencyView()
                } label: {
                    Label("Acil Numaralar & Hastaneler", systemImage: "phone.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(category.title)
        .inlineNavigationTitle()
        .sheet(item: $selectedScenario) { scenario in
            ScenarioResultSheet(scenario: scenario)
        }
    }

    private func scenarioRow(_ scenario: SymptomScenario) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(scenario.urgency.color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(scenario.urgency.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(scenario.urgency.color)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }
}

struct ScenarioResultSheet: View {
    let scenario: SymptomScenario

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    urgencyBanner

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Durum")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(scenario.label)
                            .font(.subheadline.weight(.medium))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Değerlendirme")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(scenario.advice)
                            .font(.subheadline)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Yapmanız Gerekenler")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(scenario.nextSteps, id: \.self) { step in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(scenario.urgency.color)
                                    .font(.subheadline)
                                Text(step)
                                    .font(.subheadline)
                            }
                        }
                    }

                    if scenario.urgency == .emergency {
                        emergencyButtons
                    } else if scenario.urgency == .warning {
                        warningButtons
                    }

                    Text("Bu bilgi hekim önerisinin yerine geçmez. Endişe duyduğunuzda mutlaka pediatristinize başvurun.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Değerlendirme")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private var urgencyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: scenario.urgency.icon)
                .font(.largeTitle)
                .foregroundStyle(.white)
            VStack(alignment: .leading) {
                Text(scenario.urgency.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding()
        .background(scenario.urgency.color.gradient, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var emergencyButtons: some View {
        VStack(spacing: 10) {
            #if os(iOS)
            Button {
                if let url = URL(string: "tel://112") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("112 Acil Servisi Ara", systemImage: "phone.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red, in: .rect(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            .buttonStyle(.plain)
            #endif

            NavigationLink {
                EmergencyView()
            } label: {
                Label("Tüm Acil Numaralar & Hastane", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red.opacity(0.15), in: .rect(cornerRadius: 14))
                    .foregroundStyle(.red)
                    .font(.headline)
            }
        }
    }

    @ViewBuilder
    private var warningButtons: some View {
        NavigationLink {
            EmergencyView()
        } label: {
            Label("Doktor / Acil Numaralar", systemImage: "phone.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.15), in: .rect(cornerRadius: 14))
                .foregroundStyle(.orange)
                .font(.headline)
        }
    }
}

#if os(iOS)
import UIKit
#endif
