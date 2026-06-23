import Foundation
import SwiftData

// MARK: - Export DTOs

struct DataExportPackage: Codable {
    let version: Int
    let exportedAt: Date
    let appVersion: String

    let babies: [BabyExport]
    let feedings: [FeedingExport]
    let sleeps: [SleepExport]
    let diapers: [DiaperExport]
    let vaccinations: [VaccinationExport]
    let growth: [GrowthExport]
    let medications: [MedicationExport]
    let medicationDoses: [MedicationDoseExport]
    let milkBatches: [MilkBatchExport]
    let pediatricContacts: [PediatricContactExport]
}

struct BabyExport: Codable {
    let id: UUID
    let name: String
    let birthDate: Date
    let birthTime: Date?
    let birthWeightGrams: Int?
    let birthLengthCm: Double?
    let sex: String
    let photoURL: String?
    let createdAt: Date
    let updatedAt: Date
}

struct FeedingExport: Codable {
    let id: UUID
    let babyID: UUID
    let type: String
    let startedAt: Date
    let endedAt: Date?
    let durationSeconds: Int?
    let side: String?
    let amountML: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct SleepExport: Codable {
    let id: UUID
    let babyID: UUID
    let startedAt: Date
    let endedAt: Date?
    let isNap: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct DiaperExport: Codable {
    let id: UUID
    let babyID: UUID
    let recordedAt: Date
    let type: String
    let consistency: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct VaccinationExport: Codable {
    let id: UUID
    let babyID: UUID
    let vaccineDefinitionID: String
    let scheduledDate: Date
    let completedDate: Date?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct GrowthExport: Codable {
    let id: UUID
    let babyID: UUID
    let recordedAt: Date
    let weightGrams: Int?
    let heightCm: Double?
    let headCircumferenceCm: Double?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct MedicationExport: Codable {
    let id: UUID
    let babyID: UUID
    let name: String
    let dosageText: String
    let icon: String
    let startedAt: Date
    let endedAt: Date?
    let reminderHour: Int
    let reminderMinute: Int
    let isActive: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct MedicationDoseExport: Codable {
    let id: UUID
    let medicationID: UUID
    let takenAt: Date
    let notes: String?
}

struct MilkBatchExport: Codable {
    let id: UUID
    let babyID: UUID
    let pumpedAt: Date
    let amountML: Int
    let storage: String
    let expiresAt: Date
    let usedAt: Date?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct PediatricContactExport: Codable {
    let id: UUID
    let name: String
    let phone: String?
    let address: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Service

enum DataBackupError: LocalizedError {
    case writeFailed
    case invalidFile
    case incompatibleVersion(Int)

    var errorDescription: String? {
        switch self {
        case .writeFailed:                return "Yedek dosyası oluşturulamadı."
        case .invalidFile:                return "Dosya okunamadı veya bozuk."
        case .incompatibleVersion(let v): return "Uyumsuz yedek sürümü: \(v)"
        }
    }
}

@MainActor
enum DataBackupService {
    static let currentVersion = 1

    // MARK: - Export

    static func export(from context: ModelContext) throws -> URL {
        let babies      = (try? context.fetch(FetchDescriptor<Baby>())) ?? []
        let feedings    = (try? context.fetch(FetchDescriptor<FeedingRecord>())) ?? []
        let sleeps      = (try? context.fetch(FetchDescriptor<SleepRecord>())) ?? []
        let diapers     = (try? context.fetch(FetchDescriptor<DiaperRecord>())) ?? []
        let vaccs       = (try? context.fetch(FetchDescriptor<VaccinationRecord>())) ?? []
        let growth      = (try? context.fetch(FetchDescriptor<GrowthRecord>())) ?? []
        let meds        = (try? context.fetch(FetchDescriptor<Medication>())) ?? []
        let doses       = (try? context.fetch(FetchDescriptor<MedicationDose>())) ?? []
        let milks       = (try? context.fetch(FetchDescriptor<BreastMilkBatch>())) ?? []
        let contacts    = (try? context.fetch(FetchDescriptor<PediatricContact>())) ?? []

        let package = DataExportPackage(
            version: currentVersion,
            exportedAt: .now,
            appVersion: "1.0",
            babies: babies.map(makeExport),
            feedings: feedings.map(makeExport),
            sleeps: sleeps.map(makeExport),
            diapers: diapers.map(makeExport),
            vaccinations: vaccs.map(makeExport),
            growth: growth.map(makeExport),
            medications: meds.map(makeExport),
            medicationDoses: doses.map(makeExport),
            milkBatches: milks.map(makeExport),
            pediatricContacts: contacts.map(makeExport)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(package)

        let dateStamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let filename = "BabyCare_Yedek_\(dateStamp).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Import

    enum ImportMode {
        case replace   // Mevcut verileri tamamen sil, yedekten yükle
        case merge     // ID'ye göre eklenmeyenler eklenir
    }

    @discardableResult
    static func `import`(from url: URL, mode: ImportMode, into context: ModelContext) throws -> Int {
        // Security-scoped resource erişimi (Files app'ten gelirken)
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            throw DataBackupError.invalidFile
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let package = try? decoder.decode(DataExportPackage.self, from: data) else {
            throw DataBackupError.invalidFile
        }

        if package.version > currentVersion {
            throw DataBackupError.incompatibleVersion(package.version)
        }

        if mode == .replace {
            try? context.delete(model: Baby.self)
            try? context.delete(model: FeedingRecord.self)
            try? context.delete(model: SleepRecord.self)
            try? context.delete(model: DiaperRecord.self)
            try? context.delete(model: VaccinationRecord.self)
            try? context.delete(model: GrowthRecord.self)
            try? context.delete(model: Medication.self)
            try? context.delete(model: MedicationDose.self)
            try? context.delete(model: BreastMilkBatch.self)
            try? context.delete(model: PediatricContact.self)
        }

        // Merge için mevcut id setlerini topla
        let existingBabyIDs    = Set(((try? context.fetch(FetchDescriptor<Baby>())) ?? []).map { $0.id })
        let existingFeedIDs    = Set(((try? context.fetch(FetchDescriptor<FeedingRecord>())) ?? []).map { $0.id })
        let existingSleepIDs   = Set(((try? context.fetch(FetchDescriptor<SleepRecord>())) ?? []).map { $0.id })
        let existingDiaperIDs  = Set(((try? context.fetch(FetchDescriptor<DiaperRecord>())) ?? []).map { $0.id })
        let existingVaccIDs    = Set(((try? context.fetch(FetchDescriptor<VaccinationRecord>())) ?? []).map { $0.id })
        let existingGrowthIDs  = Set(((try? context.fetch(FetchDescriptor<GrowthRecord>())) ?? []).map { $0.id })
        let existingMedIDs     = Set(((try? context.fetch(FetchDescriptor<Medication>())) ?? []).map { $0.id })
        let existingDoseIDs    = Set(((try? context.fetch(FetchDescriptor<MedicationDose>())) ?? []).map { $0.id })
        let existingMilkIDs    = Set(((try? context.fetch(FetchDescriptor<BreastMilkBatch>())) ?? []).map { $0.id })
        let existingContactIDs = Set(((try? context.fetch(FetchDescriptor<PediatricContact>())) ?? []).map { $0.id })

        var importedCount = 0

        for b in package.babies where mode == .replace || !existingBabyIDs.contains(b.id) {
            context.insert(b.toModel()); importedCount += 1
        }
        for r in package.feedings where mode == .replace || !existingFeedIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.sleeps where mode == .replace || !existingSleepIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.diapers where mode == .replace || !existingDiaperIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.vaccinations where mode == .replace || !existingVaccIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.growth where mode == .replace || !existingGrowthIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.medications where mode == .replace || !existingMedIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.medicationDoses where mode == .replace || !existingDoseIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.milkBatches where mode == .replace || !existingMilkIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }
        for r in package.pediatricContacts where mode == .replace || !existingContactIDs.contains(r.id) {
            context.insert(r.toModel()); importedCount += 1
        }

        try context.save()
        return importedCount
    }
}

// MARK: - Model -> Export

private extension DataBackupService {
    static func makeExport(_ m: Baby) -> BabyExport {
        BabyExport(id: m.id, name: m.name, birthDate: m.birthDate, birthTime: m.birthTime,
                   birthWeightGrams: m.birthWeightGrams, birthLengthCm: m.birthLengthCm,
                   sex: m.sex.rawValue, photoURL: m.photoURL,
                   createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: FeedingRecord) -> FeedingExport {
        FeedingExport(id: m.id, babyID: m.babyID, type: m.type.rawValue,
                      startedAt: m.startedAt, endedAt: m.endedAt,
                      durationSeconds: m.durationSeconds, side: m.side?.rawValue,
                      amountML: m.amountML, notes: m.notes,
                      createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: SleepRecord) -> SleepExport {
        SleepExport(id: m.id, babyID: m.babyID, startedAt: m.startedAt, endedAt: m.endedAt,
                    isNap: m.isNap, notes: m.notes,
                    createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: DiaperRecord) -> DiaperExport {
        DiaperExport(id: m.id, babyID: m.babyID, recordedAt: m.recordedAt,
                     type: m.type.rawValue, consistency: m.consistency?.rawValue,
                     notes: m.notes, createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: VaccinationRecord) -> VaccinationExport {
        VaccinationExport(id: m.id, babyID: m.babyID,
                          vaccineDefinitionID: m.vaccineDefinitionID,
                          scheduledDate: m.scheduledDate, completedDate: m.completedDate,
                          notes: m.notes, createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: GrowthRecord) -> GrowthExport {
        GrowthExport(id: m.id, babyID: m.babyID, recordedAt: m.recordedAt,
                     weightGrams: m.weightGrams, heightCm: m.heightCm,
                     headCircumferenceCm: m.headCircumferenceCm, notes: m.notes,
                     createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: Medication) -> MedicationExport {
        MedicationExport(id: m.id, babyID: m.babyID, name: m.name, dosageText: m.dosageText,
                         icon: m.icon, startedAt: m.startedAt, endedAt: m.endedAt,
                         reminderHour: m.reminderHour, reminderMinute: m.reminderMinute,
                         isActive: m.isActive, notes: m.notes,
                         createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: MedicationDose) -> MedicationDoseExport {
        MedicationDoseExport(id: m.id, medicationID: m.medicationID,
                             takenAt: m.takenAt, notes: m.notes)
    }
    static func makeExport(_ m: BreastMilkBatch) -> MilkBatchExport {
        MilkBatchExport(id: m.id, babyID: m.babyID, pumpedAt: m.pumpedAt,
                        amountML: m.amountML, storage: m.storage.rawValue,
                        expiresAt: m.expiresAt, usedAt: m.usedAt, notes: m.notes,
                        createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
    static func makeExport(_ m: PediatricContact) -> PediatricContactExport {
        PediatricContactExport(id: m.id, name: m.name, phone: m.phone,
                               address: m.address, notes: m.notes,
                               createdAt: m.createdAt, updatedAt: m.updatedAt)
    }
}

// MARK: - Export -> Model

private extension BabyExport {
    func toModel() -> Baby {
        Baby(id: id, name: name, birthDate: birthDate, birthTime: birthTime,
             birthWeightGrams: birthWeightGrams, birthLengthCm: birthLengthCm,
             sex: BabySex(rawValue: sex) ?? .unspecified, photoURL: photoURL,
             createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension FeedingExport {
    func toModel() -> FeedingRecord {
        FeedingRecord(id: id, babyID: babyID,
                      type: FeedingType(rawValue: type) ?? .breast,
                      startedAt: startedAt, endedAt: endedAt,
                      durationSeconds: durationSeconds,
                      side: side.flatMap(BreastSide.init(rawValue:)),
                      amountML: amountML, notes: notes,
                      createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension SleepExport {
    func toModel() -> SleepRecord {
        SleepRecord(id: id, babyID: babyID, startedAt: startedAt, endedAt: endedAt,
                    isNap: isNap, notes: notes,
                    createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension DiaperExport {
    func toModel() -> DiaperRecord {
        DiaperRecord(id: id, babyID: babyID, recordedAt: recordedAt,
                     type: DiaperType(rawValue: type) ?? .pee,
                     consistency: consistency.flatMap(PooConsistency.init(rawValue:)),
                     notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension VaccinationExport {
    func toModel() -> VaccinationRecord {
        VaccinationRecord(id: id, babyID: babyID,
                          vaccineDefinitionID: vaccineDefinitionID,
                          scheduledDate: scheduledDate, completedDate: completedDate,
                          notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension GrowthExport {
    func toModel() -> GrowthRecord {
        GrowthRecord(id: id, babyID: babyID, recordedAt: recordedAt,
                     weightGrams: weightGrams, heightCm: heightCm,
                     headCircumferenceCm: headCircumferenceCm, notes: notes,
                     createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension MedicationExport {
    func toModel() -> Medication {
        Medication(id: id, babyID: babyID, name: name, dosageText: dosageText,
                   icon: icon, startedAt: startedAt, endedAt: endedAt,
                   reminderHour: reminderHour, reminderMinute: reminderMinute,
                   isActive: isActive, notes: notes,
                   createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension MedicationDoseExport {
    func toModel() -> MedicationDose {
        MedicationDose(id: id, medicationID: medicationID, takenAt: takenAt, notes: notes)
    }
}
private extension MilkBatchExport {
    func toModel() -> BreastMilkBatch {
        BreastMilkBatch(id: id, babyID: babyID, pumpedAt: pumpedAt, amountML: amountML,
                        storage: MilkStorageLocation(rawValue: storage) ?? .fridge,
                        expiresAt: expiresAt, usedAt: usedAt, notes: notes,
                        createdAt: createdAt, updatedAt: updatedAt)
    }
}
private extension PediatricContactExport {
    func toModel() -> PediatricContact {
        PediatricContact(id: id, name: name, phone: phone, address: address,
                         notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}
