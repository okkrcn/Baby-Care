import Testing
import Foundation
import SwiftData
@testable import Baby_Care

struct TeethCatalogTests {

    @Test func catalogHasTwentyUniquePrimaryTeeth() {
        #expect(PrimaryTooth.all.count == 20)
        #expect(Set(PrimaryTooth.all.map(\.id)).count == 20)
    }

    @Test func idsAreStableAndResolvable() {
        // Yedek formatında saklanan kimlikler değişmemeli.
        #expect(PrimaryTooth.with(id: "lower.left.centralIncisor")?.kind == .centralIncisor)
        #expect(PrimaryTooth.with(id: "upper.right.secondMolar")?.jaw == .upper)
        #expect(PrimaryTooth.with(id: "bilinmeyen") == nil)
    }

    @Test func rangesMatchADAChart() {
        func months(_ id: String) -> ClosedRange<Int>? { PrimaryTooth.with(id: id)?.typicalMonths }
        #expect(months("upper.left.centralIncisor") == 8...12)
        #expect(months("upper.left.lateralIncisor") == 9...13)
        #expect(months("upper.left.canine") == 16...22)
        #expect(months("upper.left.firstMolar") == 13...19)
        #expect(months("upper.left.secondMolar") == 25...33)
        #expect(months("lower.right.centralIncisor") == 6...10)
        #expect(months("lower.right.lateralIncisor") == 10...16)
        #expect(months("lower.right.canine") == 17...23)
        #expect(months("lower.right.firstMolar") == 14...18)
        #expect(months("lower.right.secondMolar") == 23...31)
    }

    @Test func leftAndRightShareTheSameRange() {
        for tooth in PrimaryTooth.all {
            let mirror = PrimaryTooth(jaw: tooth.jaw, side: tooth.side == .left ? .right : .left, kind: tooth.kind)
            #expect(tooth.typicalMonths == mirror.typicalMonths)
        }
    }

    @Test func namesAreTurkish() {
        #expect(PrimaryTooth.with(id: "upper.left.lateralIncisor")?.name == "Üst sol yan kesici")
        #expect(PrimaryTooth.with(id: "lower.right.firstMolar")?.name == "Alt sağ birinci azı")
    }

    @Test func upcomingStartsWithLowerCentralsForNewborn() {
        let upcoming = TeethCatalog.upcoming(erupted: [])
        #expect(upcoming.count == 2)
        #expect(upcoming[0].jaw == .lower && upcoming[0].kind == .centralIncisor)
        #expect(upcoming[1].jaw == .upper && upcoming[1].kind == .centralIncisor)
    }

    @Test func upcomingSkipsEruptedPairs() {
        let erupted: Set<String> = [
            "lower.left.centralIncisor", "lower.right.centralIncisor",
            "upper.left.centralIncisor", "upper.right.centralIncisor",
        ]
        let upcoming = TeethCatalog.upcoming(erupted: erupted)
        #expect(upcoming.map(\.kind) == [.lateralIncisor, .lateralIncisor])
        #expect(upcoming.map(\.jaw) == [.upper, .lower])
    }

    @Test func upcomingKeepsPairWhenOnlyOneSideErupted() {
        let upcoming = TeethCatalog.upcoming(erupted: ["lower.left.centralIncisor"])
        #expect(upcoming.first?.jaw == .lower)
        #expect(upcoming.first?.kind == .centralIncisor)
    }

    @Test func typicalWindowIsInformationalOnlyForPendingTeeth() {
        let tooth = PrimaryTooth.with(id: "upper.left.lateralIncisor")!
        #expect(TeethCatalog.isInTypicalWindow(tooth, ageInMonths: 8, erupted: []) == false)
        #expect(TeethCatalog.isInTypicalWindow(tooth, ageInMonths: 10, erupted: []) == true)
        #expect(TeethCatalog.isInTypicalWindow(tooth, ageInMonths: 10, erupted: [tooth.id]) == false)
    }

    @MainActor
    @Test func mergeImportDoesNotDuplicateSameTooth() throws {
        let schema = Schema([
            Baby.self, FeedingRecord.self, SleepRecord.self, DiaperRecord.self,
            VaccinationRecord.self, GrowthRecord.self, Medication.self, MedicationDose.self,
            PediatricContact.self, BreastMilkBatch.self, SolidFoodRecord.self,
            AllergenIntroduction.self, ToothEruption.self,
        ])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = container.mainContext
        let babyID = UUID()
        context.insert(ToothEruption(babyID: babyID, toothID: "lower.left.centralIncisor"))
        try context.save()

        let package = DataExportPackage(
            version: DataBackupService.currentVersion, exportedAt: .now, appVersion: "1.7",
            babies: [], feedings: [], sleeps: [], diapers: [], vaccinations: [], growth: [],
            medications: [], medicationDoses: [], milkBatches: [], pediatricContacts: [],
            solidFoods: nil, allergenIntroductions: nil,
            toothEruptions: [
                ToothEruptionExport(id: UUID(), babyID: babyID, toothID: "lower.left.centralIncisor",
                                    eruptedAt: .now, notes: nil, createdAt: .now, updatedAt: .now),
                ToothEruptionExport(id: UUID(), babyID: babyID, toothID: "lower.right.centralIncisor",
                                    eruptedAt: .now, notes: nil, createdAt: .now, updatedAt: .now),
            ]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try encoder.encode(package).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        _ = try DataBackupService.import(from: url, mode: .merge, into: context)

        let teeth = try context.fetch(FetchDescriptor<ToothEruption>())
        #expect(teeth.count == 2)
        #expect(Set(teeth.map(\.toothID)) == ["lower.left.centralIncisor", "lower.right.centralIncisor"])
    }
}

struct ToothArchLayoutTests {
    @Test func babysRightIsOnViewersLeft() {
        let right = ToothArchView.layout(for: PrimaryTooth(jaw: .upper, side: .right, kind: .canine))
        let left = ToothArchView.layout(for: PrimaryTooth(jaw: .upper, side: .left, kind: .canine))
        #expect(right.center.x < 150)
        #expect(left.center.x > 150)
    }

    @Test func upperTeethSitAboveLowerTeeth() {
        for kind in ToothKind.allCases {
            let upper = ToothArchView.layout(for: PrimaryTooth(jaw: .upper, side: .left, kind: kind))
            let lower = ToothArchView.layout(for: PrimaryTooth(jaw: .lower, side: .left, kind: kind))
            #expect(upper.center.y < 124 && lower.center.y > 124)
        }
    }

    @Test func tappingEachToothCenterSelectsThatTooth() {
        for scale in [CGFloat(1.0), 1.2] {
            for tooth in PrimaryTooth.all {
                let c = ToothArchView.layout(for: tooth).center
                let hit = ToothArchView.nearestTooth(to: CGPoint(x: c.x * scale, y: c.y * scale), scale: scale)
                #expect(hit == tooth, "\(tooth.id) @\(scale)")
            }
        }
    }

    @Test func tappingFarFromTeethSelectsNothing() {
        #expect(ToothArchView.nearestTooth(to: CGPoint(x: 150, y: 124), scale: 1) == nil)
    }
}
