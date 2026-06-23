import SwiftUI
import SwiftData

struct MilkStorageView: View {
    let baby: Baby

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BreastMilkBatch.pumpedAt, order: .reverse) private var allBatches: [BreastMilkBatch]

    @State private var showAddSheet = false
    @State private var editingBatch: BreastMilkBatch?

    private var batches: [BreastMilkBatch] {
        allBatches.filter { $0.babyID == baby.id }
    }

    private var activeBatches: [BreastMilkBatch] {
        batches.filter { $0.isActive }.sorted { $0.expiresAt < $1.expiresAt }
    }

    private var pastBatches: [BreastMilkBatch] {
        batches.filter { !$0.isActive }
    }

    private var totalActiveML: Int {
        activeBatches.reduce(0) { $0 + $1.amountML }
    }

    var body: some View {
        List {
            if !activeBatches.isEmpty {
                Section {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                        Text("Stoktaki Toplam")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(totalActiveML) ml")
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }

            if activeBatches.isEmpty && pastBatches.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("Henüz kayıt yok", systemImage: "drop.fill")
                    } description: {
                        Text("Sağdığınız sütü ekleyin, otomatik son kullanma tarihi ve hatırlatma alın.")
                    } actions: {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Süt Ekle", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            if !activeBatches.isEmpty {
                Section("Aktif Saklama") {
                    ForEach(activeBatches) { batch in
                        Button {
                            editingBatch = batch
                        } label: {
                            row(batch)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                markUsed(batch)
                            } label: {
                                Label("Kullanıldı", systemImage: "checkmark")
                            }
                            .tint(.green)
                            Button(role: .destructive) {
                                Task { await delete(batch) }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if !pastBatches.isEmpty {
                Section("Geçmiş") {
                    ForEach(pastBatches) { batch in
                        row(batch)
                            .opacity(0.7)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await delete(batch) }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            Section {
                Text("Saklama süreleri CDC ve WHO anne sütü saklama kılavuzlarına göre ideal değerlerdir. Bebeğinizin sağlığı için en kısa süre tercih edilmelidir. Çözülmüş süt yeniden dondurulmamalıdır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Süt Sağma")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MilkBatchAddSheet(babyID: baby.id, babyName: baby.name)
        }
        .sheet(item: $editingBatch) { batch in
            MilkBatchAddSheet(babyID: baby.id, babyName: baby.name, editing: batch)
        }
    }

    @ViewBuilder
    private func row(_ batch: BreastMilkBatch) -> some View {
        HStack(spacing: 12) {
            Image(systemName: batch.storage.icon)
                .font(.title3)
                .foregroundStyle(statusColor(batch))
                .frame(width: 40, height: 40)
                .background(statusColor(batch).opacity(0.15), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(batch.amountML) ml")
                        .font(.subheadline.weight(.semibold))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(batch.storage.localizedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Sağıldı: \(DateFormatters.displayDate.string(from: batch.pumpedAt)) \(DateFormatters.displayTime.string(from: batch.pumpedAt))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                statusLabel(batch)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusLabel(_ batch: BreastMilkBatch) -> some View {
        if let used = batch.usedAt {
            Label("Kullanıldı: \(DateFormatters.displayDate.string(from: used))", systemImage: "checkmark.circle.fill")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
        } else if batch.isExpired {
            Label("Süresi doldu — kullanmayın", systemImage: "exclamationmark.triangle.fill")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.red)
        } else {
            Label("Bitiş: \(DateFormatters.displayDate.string(from: batch.expiresAt)) — \(remainingText(batch))",
                  systemImage: "clock")
                .font(.caption2.weight(.medium))
                .foregroundStyle(urgencyColor(hours: batch.hoursUntilExpiry))
        }
    }

    private func remainingText(_ batch: BreastMilkBatch) -> String {
        let hours = batch.hoursUntilExpiry
        if hours < 1 {
            return "\(max(0, Int(hours * 60))) dk kaldı"
        } else if hours < 48 {
            return "\(Int(hours)) saat kaldı"
        } else {
            return "\(Int(hours / 24)) gün kaldı"
        }
    }

    private func statusColor(_ batch: BreastMilkBatch) -> Color {
        if batch.isUsed { return .green }
        if batch.isExpired { return .red }
        if batch.hoursUntilExpiry < 24 { return .orange }
        return .blue
    }

    private func urgencyColor(hours: Double) -> Color {
        if hours < 2 { return .red }
        if hours < 24 { return .orange }
        return .secondary
    }

    private func markUsed(_ batch: BreastMilkBatch) {
        batch.usedAt = .now
        batch.updatedAt = .now
        try? modelContext.save()
        Task {
            await NotificationService.cancelExpiryReminder(for: batch)
        }
    }

    private func delete(_ batch: BreastMilkBatch) async {
        await NotificationService.cancelExpiryReminder(for: batch)
        modelContext.delete(batch)
        try? modelContext.save()
    }
}
