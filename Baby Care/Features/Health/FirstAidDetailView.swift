import SwiftUI

struct FirstAidDetailView: View {
    let scenario: FirstAidScenario

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: scenario.icon)
                        .font(.title)
                        .foregroundStyle(scenario.color)
                        .frame(width: 50, height: 50)
                        .background(scenario.color.opacity(0.15), in: .circle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scenario.title)
                            .font(.title3.bold())
                        Text(scenario.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            #if os(iOS)
            if scenario.callEmergency {
                Section {
                    Button {
                        if let url = URL(string: "tel://112") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("112 Acil Servisi Ara", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.red)
                }
            }
            #endif

            if !scenario.callEmergencyWhen.isEmpty {
                Section {
                    ForEach(scenario.callEmergencyWhen, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text(line)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label("112'yi Şu Durumlarda Arayın", systemImage: "exclamationmark.octagon.fill")
                        .foregroundStyle(.red)
                }
            }

            Section("Adım Adım Müdahale") {
                ForEach(scenario.steps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.id)")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(scenario.color, in: .circle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))
                            if let detail = step.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if !scenario.warnings.isEmpty {
                Section {
                    ForEach(scenario.warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundStyle(.orange)
                                .font(.subheadline)
                            Text(warning)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label("Yapmayın", systemImage: "hand.raised.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Text("Bu rehber bilgilendirme amaçlıdır; profesyonel eğitimin yerine geçmez. Endişe duyduğunuzda mutlaka pediatristinize başvurun veya 112'yi arayın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(scenario.title)
        .inlineNavigationTitle()
    }
}

#if os(iOS)
import UIKit
#endif
