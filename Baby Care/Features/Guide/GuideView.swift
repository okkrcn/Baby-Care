import SwiftUI

struct GuideView: View {
    let baby: Baby

    @State private var selectedStageID: String

    init(baby: Baby) {
        self.baby = baby
        let current = GuideCatalog.stage(forAgeWeeks: baby.ageInWeeks)
        self._selectedStageID = State(initialValue: current.id)
    }

    private var stage: GuideStage {
        GuideCatalog.stages.first { $0.id == selectedStageID } ?? GuideCatalog.stages[0]
    }

    private var currentStageID: String {
        GuideCatalog.stage(forAgeWeeks: baby.ageInWeeks).id
    }

    var body: some View {
        List {
            Section {
                Picker("Aşama", selection: $selectedStageID) {
                    ForEach(GuideCatalog.stages) { s in
                        Text(s.title).tag(s.id)
                    }
                }
                .pickerStyle(.menu)

                if stage.id == currentStageID {
                    Label("Bebeğinizin şu anki aşaması", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.pink)
                }

                Text(stage.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            } header: {
                Text(stage.title)
            }

            if !stage.grossMotor.isEmpty {
                listSection("Kaba Motor", icon: "figure.walk", items: stage.grossMotor, color: .blue)
            }
            if !stage.fineMotor.isEmpty {
                listSection("İnce Motor", icon: "hand.raised.fill", items: stage.fineMotor, color: .purple)
            }
            if !stage.language.isEmpty {
                listSection("Dil ve İletişim", icon: "bubble.left.fill", items: stage.language, color: .teal)
            }
            if !stage.socialEmotional.isEmpty {
                listSection("Sosyal-Duygusal", icon: "heart.fill", items: stage.socialEmotional, color: .pink)
            }
            if !stage.feedingTips.isEmpty {
                listSection("Beslenme", icon: "drop.fill", items: stage.feedingTips, color: .cyan)
            }
            if !stage.sleepTips.isEmpty {
                listSection("Uyku", icon: "moon.zzz.fill", items: stage.sleepTips, color: .indigo)
            }

            if !stage.warningSigns.isEmpty {
                Section {
                    ForEach(stage.warningSigns, id: \.self) { sign in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(sign)
                        }
                    }
                } header: {
                    Label("Hekime Başvurma İşaretleri", systemImage: "stethoscope")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Text("İçerik DSÖ, T.C. Sağlık Bakanlığı ve AAP gelişim rehberlerine dayanır. Bilgilendirme amaçlıdır; her bebek farklı hızda gelişir. Endişe duyduğunuzda mutlaka pediatristinize danışın.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Gelişim Rehberi")
    }

    private func listSection(_ title: String, icon: String, items: [String], color: Color) -> some View {
        Section {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(color)
                        .padding(.top, 8)
                    Text(item)
                }
            }
        } header: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
        }
    }
}
