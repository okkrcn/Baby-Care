import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(SelectedBabyStore.self) private var babyStore
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Baby.birthDate) private var babies: [Baby]
    @Query(sort: \FeedingRecord.startedAt, order: .reverse) private var allFeedings: [FeedingRecord]
    @Query(sort: \SleepRecord.startedAt, order: .reverse) private var allSleeps: [SleepRecord]
    @Query(sort: \DiaperRecord.recordedAt, order: .reverse) private var allDiapers: [DiaperRecord]
    @Query(sort: \VaccinationRecord.scheduledDate) private var allVaccinations: [VaccinationRecord]
    @Query(sort: \GrowthRecord.recordedAt, order: .reverse) private var allGrowth: [GrowthRecord]
    @Query(sort: \SolidFoodRecord.servedAt, order: .reverse) private var allSolids: [SolidFoodRecord]

    @State private var quickActionFeedback: String?
    @State private var feedbackOpacity: Double = 0
    @State private var showDiaperDialog = false
    @State private var showFeedingAmount = false
    @State private var feedingAmountText = ""

    private var baby: Baby? { babyStore.resolved(from: babies) }

    private var ongoingSleep: SleepRecord? {
        guard let id = baby?.id else { return nil }
        return allSleeps.first { $0.babyID == id && $0.isOngoing }
    }

    private var ongoingFeeding: FeedingRecord? {
        guard let id = baby?.id else { return nil }
        return allFeedings.first { $0.babyID == id && $0.isOngoing }
    }

    private var nextVaccination: VaccinationRecord? {
        guard let id = baby?.id else { return nil }
        return allVaccinations.first {
            $0.babyID == id && $0.completedDate == nil && $0.daysFromToday >= 0
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let baby {
                        babyHeader(baby)
                        emergencyHelpCard
                        if baby.stage.isSolidFoodAge {
                            solidFoodCard(baby: baby)
                        }
                        quickActionsSection(baby: baby)
                        if let next = nextVaccination {
                            nextVaccinationCard(next)
                        }
                        weeklySummaryCard(baby: baby)
                        growthCard(baby: baby)
                        lastActivitiesSection(baby: baby)
                        tipSection(baby: baby)
                    } else {
                        ContentUnavailableView(
                            "Bebek bilgisi yok",
                            systemImage: "figure.and.child.holdinghands",
                            description: Text("Bebek sekmesinden bir bebek ekleyin.")
                        )
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            .navigationTitle("Ana Sayfa")
            .toolbar {
                if babies.count > 1 {
                    ToolbarItem(placement: .principal) {
                        BabyPickerToolbarMenu(babies: babies, selected: baby)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private func babyHeader(_ baby: Baby) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Merhaba")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(baby.name)
                .font(.largeTitle.bold())
            Text(ageDescription(baby))
                .font(.title3)
                .foregroundStyle(.pink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Emergency help card

    private var emergencyHelpCard: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SymptomCheckerView()
            } label: {
                helpButton(
                    title: "Bu Normal Mi?",
                    subtitle: "Belirti kontrolü",
                    icon: "stethoscope",
                    color: .orange
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                EmergencyView()
            } label: {
                helpButton(
                    title: "Acil Yardım",
                    subtitle: "112 · doktor · hastane",
                    icon: "phone.fill",
                    color: .red
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func helpButton(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.18), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10), in: .rect(cornerRadius: 14))
    }

    // MARK: - Quick actions

    private func quickActionsSection(baby: Baby) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hızlı Eylemler")
                .font(.headline)

            HStack(spacing: 10) {
                quickAction(
                    title: ongoingSleep == nil ? "Uyku Başlat" : "Uyku Sürüyor",
                    icon: ongoingSleep == nil ? "moon.zzz.fill" : "moon.zzz",
                    color: .indigo,
                    isActive: ongoingSleep != nil
                ) {
                    toggleSleep(for: baby)
                }

                quickAction(
                    title: "Beslenme",
                    icon: "drop.fill",
                    color: .blue,
                    isActive: false
                ) {
                    feedingAmountText = ""
                    showFeedingAmount = true
                }

                quickAction(
                    title: "Bez",
                    icon: "leaf.fill",
                    color: .green,
                    isActive: false
                ) {
                    showDiaperDialog = true
                }
            }

            if let msg = quickActionFeedback {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(feedbackOpacity)
                    .animation(.easeInOut(duration: 0.3), value: feedbackOpacity)
            }
        }
        .confirmationDialog("Bez Değişimi", isPresented: $showDiaperDialog, titleVisibility: .visible) {
            Button("Çiş") { logDiaper(.pee, for: baby) }
            Button("Kaka") { logDiaper(.poo, for: baby) }
            Button("Karışık") { logDiaper(.both, for: baby) }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Kaç CC içti?", isPresented: $showFeedingAmount) {
            TextField("Örn: 90", text: $feedingAmountText)
                .numericKeyboard()
            Button("Sağılmış süt") { saveFeedingAmount(.bottleBreastmilk, for: baby) }
            Button("Mama") { saveFeedingAmount(.bottleFormula, for: baby) }
            Button("Vazgeç", role: .cancel) { feedingAmountText = "" }
        } message: {
            Text("Miktarı yazıp süt türünü seçin.")
        }
    }

    private func quickAction(title: String, icon: String, color: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(isActive ? .white : color)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isActive ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isActive ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color.opacity(0.12)),
                in: .rect(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }

    private func toggleSleep(for baby: Baby) {
        do {
            let msg = try QuickLogService.toggleSleep(for: baby, ongoing: ongoingSleep, in: modelContext)
            Haptics.success()
            showFeedback(msg)
        } catch {
            showFeedback("Kaydedilemedi: \(error.localizedDescription)")
        }
    }

    private func saveFeedingAmount(_ type: FeedingType, for baby: Baby) {
        guard let ml = Int(feedingAmountText.trimmingCharacters(in: .whitespaces)), ml > 0 else {
            showFeedback("Geçerli bir CC miktarı girin.")
            return
        }
        do {
            let msg = try QuickLogService.logBottle(type, amountML: ml, for: baby, in: modelContext)
            Haptics.success()
            showFeedback(msg)
            feedingAmountText = ""
        } catch {
            showFeedback("Kaydedilemedi: \(error.localizedDescription)")
        }
    }

    private func logDiaper(_ type: DiaperType, for baby: Baby) {
        do {
            let msg = try QuickLogService.logDiaper(type, for: baby, in: modelContext)
            Haptics.success()
            showFeedback(msg)
        } catch {
            showFeedback("Kaydedilemedi: \(error.localizedDescription)")
        }
    }

    private func showFeedback(_ message: String) {
        quickActionFeedback = message
        withAnimation { feedbackOpacity = 1 }

        // Aktif kullanıma puan iste tetikleyici
        ReviewRequester.registerInteraction()

        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation { feedbackOpacity = 0 }
            }
        }
    }

    // MARK: - Next vaccination

    private func nextVaccinationCard(_ rec: VaccinationRecord) -> some View {
        let days = rec.daysFromToday
        let badge: String
        let badgeColor: Color
        if days == 0 {
            badge = "Bugün"
            badgeColor = .orange
        } else if days <= 7 {
            badge = "\(days) gün kaldı"
            badgeColor = .orange
        } else {
            badge = "\(days) gün kaldı"
            badgeColor = .secondary
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "syringe.fill")
                    .foregroundStyle(.pink)
                Text("Sıradaki Aşı")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(badge)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(badgeColor)
            }
            Text(rec.definition?.shortName ?? rec.vaccineDefinitionID)
                .font(.title3.bold())
            Text(DateFormatters.displayDate.string(from: rec.scheduledDate))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.pink.opacity(0.10), in: .rect(cornerRadius: 16))
    }

    // MARK: - Weekly summary card

    private func weeklySummaryCard(baby: Baby) -> some View {
        NavigationLink {
            WeeklySummaryView(baby: baby)
        } label: {
            let summary = WeeklySummaryCalculator.calculate(
                for: baby,
                feedings: allFeedings,
                sleeps: allSleeps,
                diapers: allDiapers,
                growth: [],
                vaccinations: allVaccinations,
                solidFoods: allSolids
            )
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(.teal)
                    .frame(width: 44, height: 44)
                    .background(.teal.opacity(0.15), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bu Hafta")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    HStack(spacing: 12) {
                        Label("\(summary.totalFeedings) öğün", systemImage: "drop.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label(String(format: "%.0f sa uyku", summary.averageSleepHoursPerDay * 7), systemImage: "moon.zzz.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(.teal.opacity(0.06), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Growth card

    private var latestGrowth: GrowthRecord? {
        guard let id = baby?.id else { return nil }
        return allGrowth.first { $0.babyID == id }
    }

    // MARK: - Ek gıda kartı

    private func solidFoodCard(baby: Baby) -> some View {
        let todaysMeals = allSolids.filter {
            $0.babyID == baby.id && Calendar.current.isDateInToday($0.servedAt)
        }.count

        return NavigationLink {
            SolidFoodView(baby: baby)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "carrot.fill")
                    .font(.title2)
                    .foregroundStyle(.brown)
                    .frame(width: 44, height: 44)
                    .background(.brown.opacity(0.15), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ek Gıda")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(todaysMeals == 0
                         ? "Rehber, besin kütüphanesi ve alerjen takibi"
                         : "Bugün \(todaysMeals) öğün kaydedildi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(.brown.opacity(0.08), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func growthCard(baby: Baby) -> some View {
        NavigationLink {
            GrowthView(baby: baby)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.purple)
                    .frame(width: 44, height: 44)
                    .background(.purple.opacity(0.15), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Büyüme & Ölçüm")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let g = latestGrowth {
                        Text(growthSummary(g))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Henüz ölçüm yok — eklemek için dokun")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(.purple.opacity(0.06), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func growthSummary(_ g: GrowthRecord) -> String {
        var parts: [String] = []
        if let w = g.weightGrams { parts.append("\(w) g") }
        if let h = g.heightCm { parts.append(String(format: "%.1f cm", h)) }
        if let head = g.headCircumferenceCm { parts.append(String(format: "baş %.1f cm", head)) }
        let date = DateFormatters.displayDate.string(from: g.recordedAt)
        return parts.isEmpty ? date : "\(parts.joined(separator: " · ")) — \(date)"
    }

    // MARK: - Last activities

    private func lastActivitiesSection(baby: Baby) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son Kayıtlar")
                .font(.headline)

            VStack(spacing: 12) {
                lastFeedingCard(baby: baby)
                lastSleepCard(baby: baby)
                lastDiaperCard(baby: baby)
            }
        }
    }

    private func lastFeedingCard(baby: Baby) -> some View {
        let last = allFeedings.first { $0.babyID == baby.id }
        return summaryCard(
            icon: "drop.fill",
            color: .blue,
            title: "Son Beslenme",
            primary: last.map { relativeString(from: $0.startedAt) } ?? "Kayıt yok",
            secondary: last.map(feedingSubtitle) ?? "—"
        )
    }

    private func lastSleepCard(baby: Baby) -> some View {
        let last = allSleeps.first { $0.babyID == baby.id }
        let primary: String
        let secondary: String
        if let s = last {
            primary = s.isOngoing ? "Devam ediyor" : relativeString(from: s.startedAt)
            secondary = s.isOngoing
                ? "Başladı: \(DateFormatters.displayTime.string(from: s.startedAt))"
                : "\(s.isNap ? "Gündüz" : "Gece") · \(DurationFormatter.string(fromSeconds: s.durationSeconds))"
        } else {
            primary = "Kayıt yok"
            secondary = "—"
        }
        return summaryCard(icon: "moon.zzz.fill", color: .indigo, title: "Son Uyku", primary: primary, secondary: secondary)
    }

    private func lastDiaperCard(baby: Baby) -> some View {
        let last = allDiapers.first { $0.babyID == baby.id }
        return summaryCard(
            icon: "leaf.fill",
            color: .green,
            title: "Son Bez",
            primary: last.map { relativeString(from: $0.recordedAt) } ?? "Kayıt yok",
            secondary: last?.type.localizedTitle ?? "—"
        )
    }

    private func summaryCard(icon: String, color: Color, title: String, primary: String, secondary: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(primary).font(.subheadline.weight(.semibold))
                Text(secondary).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
    }

    // MARK: - Tip

    private func tipSection(baby: Baby) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bilgi")
                .font(.headline)
            Text(weeklyTip(forAgeWeeks: baby.ageInWeeks))
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.pink.opacity(0.08), in: .rect(cornerRadius: 14))
            Text("Bu içerik bilgilendirme amaçlıdır; hekim önerisinin yerini tutmaz.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func weeklyTip(forAgeWeeks weeks: Int) -> String {
        switch weeks {
        case ..<2:
            return "İlk haftalarda her öğünde 60 ml'ye kadar beslenme normaldir. Günde 8–12 kez emzirme önerilir."
        case 2..<6:
            return "1 aya yaklaşırken mide kapasitesi 125–150 ml'ye ulaşır; günde 6–10 emzirme tipiktir."
        case 6..<12:
            return "2–3. ayda gece uykuları uzamaya başlar. Sosyal gülümseme görülebilir."
        case 12..<18:
            return "3. ayda günde ortalama 15 saat uyku — 10 saati gece, kalanı gündüz şekerlemeleri."
        case 18..<26:
            return "5. ay civarında bebek elini ağzına götürür, ses çıkarmaktan keyif alır."
        case 26..<35:
            return "Ek gıda 6. ay dolunca başlar. Demir açısından zengin besinler önceliklidir; anne sütü ana besin olmayı sürdürür."
        case 35..<52:
            return "9-11 ayda kıvam incelir: ezilmiş yerine ince doğranmış. Günde 3-4 ana öğün, iştaha göre 1-2 ara öğün."
        case 52..<78:
            return "1 yaşından sonra çocuk aile yemeklerini yiyebilir. İnek sütü artık ana içecek olabilir; ilave şeker 2 yaşına kadar önerilmez."
        default:
            return "18-24 ayda seçici yeme normaldir. Ne sunulacağına siz, ne kadar yiyeceğine çocuk karar verir."
        }
    }

    // MARK: - Helpers

    private func ageDescription(_ baby: Baby) -> String {
        let days = baby.ageInDays
        if days < 14 { return "\(days) günlük" }
        let weeks = baby.ageInWeeks
        if weeks < 12 { return "\(weeks) haftalık" }
        return "\(baby.ageInMonths) aylık"
    }

    private func feedingSubtitle(_ f: FeedingRecord) -> String {
        if let dur = f.durationSeconds {
            return "\(f.type.localizedTitle) · \(DurationFormatter.string(fromSeconds: dur))"
        } else if let ml = f.amountML {
            return "\(f.type.localizedTitle) · \(ml) ml"
        }
        return f.type.localizedTitle
    }

    private func relativeString(from date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: .now)
    }
}
