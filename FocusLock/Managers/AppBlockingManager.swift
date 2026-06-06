// Менеджер блокування — центральна точка управління
import Foundation
import FamilyControls
import SwiftData

@MainActor
final class AppBlockingManager: ObservableObject {

    static let shared = AppBlockingManager()

    private let managedSettings = ManagedSettingsService.shared
    private let deviceActivity = DeviceActivityService.shared

    @Published var currentSelection: FamilyActivitySelection = FamilyActivitySelection()
    @Published var hasBlockedApps: Bool = false

    private var groupDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    private init() {
        loadSavedSelection()
    }

    // MARK: - Selection persistence

    func loadSavedSelection() {
        if let selection = FamilyActivitySelectionStorage.load() {
            currentSelection = selection
        }
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        guard FamilyActivitySelectionStorage.save(selection) else {
            AppCoordinator.shared.presentError(.persistenceFailed("Не вдалося зберегти вибір додатків."))
            return
        }
        currentSelection = selection
    }

    // MARK: - Sync SwiftData limits from picker selection

    /// DEBUG UI Preview: insert demo limits without FamilyActivityPicker tokens.
    func injectDemoLimits(
        context: ModelContext,
        appNames: [String],
        defaultMinutes: Int = 60
    ) throws {
        let existing = try context.fetch(FetchDescriptor<AppLimit>())
        var unmatched = existing

        for name in appNames {
            let bundleID = "focuslock.demo.\(name.lowercased())"
            if let idx = unmatched.firstIndex(where: { $0.bundleIdentifier == bundleID }) {
                let limit = unmatched.remove(at: idx)
                limit.appName = name
                limit.limitMinutes = defaultMinutes
                limit.isEnabled = true
            } else {
                context.insert(AppLimit(
                    appName: name,
                    bundleIdentifier: bundleID,
                    tokenData: nil,
                    limitMinutes: defaultMinutes
                ))
            }
            MockDeviceActivityService.shared.simulateUsage(bundleId: bundleID, minutes: defaultMinutes / 3)
        }

        for limit in unmatched where limit.bundleIdentifier.hasPrefix("focuslock.demo.") {
            deviceActivity.stopMonitoring(limitID: limit.id)
            context.delete(limit)
        }

        try context.save()
    }

    func syncLimits(
        from selection: FamilyActivitySelection,
        context: ModelContext,
        defaultMinutes: Int = 60
    ) throws {
        let existing = try context.fetch(FetchDescriptor<AppLimit>())
        var unmatched = existing

        var index = 1
        for token in selection.applicationTokens {
            guard let tokenData = FamilyActivitySelectionStorage.encodeSingleToken(token) else { continue }
            let bundleID = Self.bundleIdentifier(forTokenData: tokenData)

            if let matchIndex = unmatched.firstIndex(where: { $0.tokenData == tokenData }) {
                let limit = unmatched.remove(at: matchIndex)
                limit.tokenData = tokenData
                limit.bundleIdentifier = bundleID
            } else {
                let limit = AppLimit(
                    appName: "Додаток \(index)",
                    bundleIdentifier: bundleID,
                    tokenData: tokenData,
                    limitMinutes: defaultMinutes
                )
                context.insert(limit)
            }
            index += 1
        }

        for limit in unmatched {
            deviceActivity.stopMonitoring(limitID: limit.id)
            context.delete(limit)
        }

        try context.save()
    }

    // MARK: - Extension state → SwiftData

    func syncExtensionState(context: ModelContext) {
        guard let limits = try? context.fetch(FetchDescriptor<AppLimit>()) else { return }
        var changed = false

        for limit in limits {
            let blocked = groupDefaults.bool(forKey: AppGroupConstants.limitBlockedKey(limitID: limit.id))
            if limit.isCurrentlyBlocked != blocked {
                limit.isCurrentlyBlocked = blocked
                changed = true
            }
        }

        if changed { try? context.save() }
    }

    // MARK: - Blocking

    func applyBlocking(for selection: FamilyActivitySelection) {
        managedSettings.blockApps(selection: selection)
        hasBlockedApps = true
        groupDefaults.set(true, forKey: AppGroupConstants.focusSessionActiveKey)
    }

    func removeAllBlocking() {
        managedSettings.unblockAll()
        hasBlockedApps = false
        groupDefaults.set(false, forKey: AppGroupConstants.focusSessionActiveKey)
    }

    func startMonitoring(limits: [AppLimit]) throws {
        #if FOCUSLOCK_MOCK_SCREEN_TIME
        if FocusLockConfig.useMockScreenTime {
            let configs = limits.filter(\.isEnabled).map { limit in
                LimitMonitoringConfig(
                    limitID: limit.id,
                    bundleIdentifier: limit.bundleIdentifier,
                    tokenData: limit.tokenData ?? Data(),
                    limitMinutes: limit.bonusUsedToday ? limit.effectiveLimitMinutes : limit.limitMinutes,
                    includesBonus: false
                )
            }
            try deviceActivity.startMonitoring(configs: configs)
            return
        }
        #endif

        guard ScreenTimeService.shared.isAuthorized else {
            throw AppError.authorizationDenied
        }

        let settings = SettingsRepository.shared.cachedSettings
        groupDefaults.set(settings?.strictModeEnabled ?? false, forKey: AppGroupConstants.strictModeKey)

        let activeLimits = limits.filter(\.isEnabled)
        let strict = settings?.strictModeEnabled ?? false

        let configs = activeLimits.compactMap { limit -> LimitMonitoringConfig? in
            guard let tokenData = limit.tokenData else { return nil }
            let threshold = limit.bonusUsedToday
                ? limit.effectiveLimitMinutes
                : limit.limitMinutes
            return LimitMonitoringConfig(
                limitID: limit.id,
                bundleIdentifier: limit.bundleIdentifier,
                tokenData: tokenData,
                limitMinutes: threshold,
                includesBonus: !strict && !limit.bonusUsedToday && !isDailyBonusUsed()
            )
        }

        if configs.isEmpty, !currentSelection.applicationTokens.isEmpty {
            let maxMinutes = limits.map(\.limitMinutes).max() ?? 60
            try startMonitoring(
                selection: currentSelection,
                limitMinutes: maxMinutes,
                includesBonus: !strict && !isDailyBonusUsed()
            )
            return
        }

        try deviceActivity.startMonitoring(configs: configs)
    }

    func startMonitoring(
        selection: FamilyActivitySelection,
        limitMinutes: Int,
        includesBonus: Bool = false
    ) throws {
        #if FOCUSLOCK_MOCK_SCREEN_TIME
        if FocusLockConfig.useMockScreenTime {
            guard let data = try? PropertyListEncoder().encode(selection) else { return }
            try deviceActivity.startMonitoring(
                selectionData: data,
                limitMinutes: limitMinutes,
                includesBonus: includesBonus
            )
            return
        }
        #endif

        guard ScreenTimeService.shared.isAuthorized else {
            throw AppError.authorizationDenied
        }
        guard let data = try? PropertyListEncoder().encode(selection) else {
            throw AppError.monitoringFailed("Не вдалося зберегти вибір додатків.")
        }
        try deviceActivity.startMonitoring(
            selectionData: data,
            limitMinutes: limitMinutes,
            includesBonus: includesBonus
        )
    }

    func stopMonitoring() {
        deviceActivity.stopMonitoring()
    }

    func stopAllMonitoring(for limits: [AppLimit]) {
        var names = limits.map { FocusLockActivity.perLimitRaw(limitID: $0.id) }
        names.append(FocusLockActivity.dailyMonitoringRaw)
        deviceActivity.stopAllMonitoring(activityNames: names)
    }

    func stopMonitoring(for limit: AppLimit) {
        deviceActivity.stopMonitoring(limitID: limit.id)
    }

    // MARK: - Daily bonus (one per day, app-wide)

    func isDailyBonusUsed(on date: Date = Date()) -> Bool {
        groupDefaults.bool(forKey: AppGroupConstants.dailyBonusKey(for: date))
    }

    var isStrictModeEnabled: Bool {
        groupDefaults.bool(forKey: AppGroupConstants.strictModeKey)
    }

    func markDailyBonusUsed() {
        groupDefaults.set(true, forKey: AppGroupConstants.dailyBonusKey())
        groupDefaults.set(true, forKey: AppGroupConstants.pendingBonusKey)
    }

    func consumePendingBonusFlag() -> Bool {
        guard groupDefaults.bool(forKey: AppGroupConstants.pendingBonusKey) else { return false }
        groupDefaults.removeObject(forKey: AppGroupConstants.pendingBonusKey)
        return true
    }

    func applyPendingBonusToLimits(context: ModelContext) throws {
        guard consumePendingBonusFlag() else { return }

        let limits = try context.fetch(FetchDescriptor<AppLimit>())
        var changed = false
        for limit in limits where !limit.bonusUsedToday {
            limit.bonusUsedToday = true
            limit.isCurrentlyBlocked = false
            groupDefaults.set(false, forKey: AppGroupConstants.limitBlockedKey(limitID: limit.id))
            changed = true
        }
        if changed {
            try context.save()
            removeAllBlocking()
            try startMonitoring(limits: limits)
        }
    }

    static func bundleIdentifier(forTokenData data: Data) -> String {
        var hash = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return "focuslock.token.\(hash)"
    }
}
