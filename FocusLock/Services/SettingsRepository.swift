import Foundation
import SwiftData

@MainActor
final class SettingsRepository {

    static let shared = SettingsRepository()

    private(set) var cachedSettings: AppSettings?

    private init() {}

    @discardableResult
    func ensureSettings(context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let all = (try? context.fetch(descriptor)) ?? []

        if all.count > 1 {
            let keeper = all[0]
            for duplicate in all.dropFirst() {
                context.delete(duplicate)
            }
            try? context.save()
            cachedSettings = keeper
            return keeper
        }

        if let existing = all.first {
            cachedSettings = existing
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)
        do {
            try context.save()
        } catch {
            AppCoordinator.shared.presentError(.persistenceFailed(error.localizedDescription))
        }
        cachedSettings = settings
        return settings
    }

    func settings(context: ModelContext) -> AppSettings {
        ensureSettings(context: context)
    }
}
