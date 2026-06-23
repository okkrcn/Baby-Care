import AppIntents

/// Home Screen'de uygulamaya uzun basınca açılan hızlı eylemler menüsü.
/// Spotlight ve Siri'den de tetiklenir.
struct BabyCareAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSleepIntent(),
            phrases: [
                "\(.applicationName) ile uyku başlat",
                "\(.applicationName) uyku başlat",
                "Yeni uyku \(.applicationName)"
            ],
            shortTitle: "Uyku Başlat",
            systemImageName: "moon.zzz.fill"
        )

        AppShortcut(
            intent: StartFeedingIntent(),
            phrases: [
                "\(.applicationName) ile emzirme başlat",
                "\(.applicationName) emzirme başlat",
                "Yeni emzirme \(.applicationName)"
            ],
            shortTitle: "Emzirme Başlat",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: LogDiaperIntent(),
            phrases: [
                "\(.applicationName) ile bez değişimi",
                "\(.applicationName) bez değişimi ekle"
            ],
            shortTitle: "Bez Değişimi",
            systemImageName: "leaf.fill"
        )
    }
}
