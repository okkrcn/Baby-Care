import Testing
import Foundation
import SwiftData
@testable import Baby_Care

@MainActor
struct VaccinationMigrationTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Baby.self, VaccinationRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test func removesPendingRetiredRecord() async throws {
        let context = try makeContext()
        context.insert(VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "kpa_6m", scheduledDate: .now
        ))
        try context.save()

        let removed = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(removed == 1)
        let remaining = try context.fetch(FetchDescriptor<VaccinationRecord>())
        #expect(remaining.isEmpty)
    }

    @Test func keepsCompletedRetiredRecord() async throws {
        let context = try makeContext()
        let record = VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "kpa_6m", scheduledDate: .now
        )
        record.completedDate = .now
        context.insert(record)
        try context.save()

        let removed = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(removed == 0)
        let remaining = try context.fetch(FetchDescriptor<VaccinationRecord>())
        #expect(remaining.count == 1)
    }

    @Test func leavesActiveRecordsUntouched() async throws {
        let context = try makeContext()
        context.insert(VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "hexa_6m", scheduledDate: .now
        ))
        try context.save()

        let removed = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(removed == 0)
        let remaining = try context.fetch(FetchDescriptor<VaccinationRecord>())
        #expect(remaining.count == 1)
    }

    @Test func isIdempotent() async throws {
        let context = try makeContext()
        context.insert(VaccinationRecord(
            babyID: UUID(), vaccineDefinitionID: "kpa_6m", scheduledDate: .now
        ))
        try context.save()

        let first = await VaccinationMigration.removeRetiredPendingRecords(in: context)
        let second = await VaccinationMigration.removeRetiredPendingRecords(in: context)

        #expect(first == 1)
        #expect(second == 0)
    }
}
