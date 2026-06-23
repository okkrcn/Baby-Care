//
//  Baby_CareApp.swift
//  Baby Care
//
//  Created by ouzkrcn on 17.06.2026.
//

import SwiftUI
import SwiftData

@main
struct Baby_CareApp: App {
    @State private var selectedBabyStore = SelectedBabyStore()
    @State private var nightModeStore = NightModeStore()

    /// AppIntents (App Shortcuts) tarafından erişilen paylaşımlı container.
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Baby.self,
            FeedingRecord.self,
            SleepRecord.self,
            DiaperRecord.self,
            VaccinationRecord.self,
            GrowthRecord.self,
            Medication.self,
            MedicationDose.self,
            PediatricContact.self,
            BreastMilkBatch.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(selectedBabyStore)
                .environment(nightModeStore)
                .preferredColorScheme(nightModeStore.isActive ? .dark : nil)
                .tint(nightModeStore.isActive ? .red : .pink)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
