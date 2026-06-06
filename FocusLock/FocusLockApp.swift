import SwiftUI
import SwiftData

@main
struct FocusLockApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppLimit.self,
            DailyStats.self,
            AppUsageRecord.self,
            AppSettings.self,
            FocusSession.self,
            DailyStreakRecord.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("FocusLock: Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
