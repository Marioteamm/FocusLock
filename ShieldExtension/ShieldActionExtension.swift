// Shield action handler — "Add 15 Minutes" (once per day) and Close
import FamilyControls
import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate {

    private var sharedDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldResponse) -> Void
    ) {
        handleShieldAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldResponse) -> Void
    ) {
        handleShieldAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for domain: WebDomainToken,
        completionHandler: @escaping (ShieldResponse) -> Void
    ) {
        handleShieldAction(action, completionHandler: completionHandler)
    }

    private func handleShieldAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            if canUseDailyBonus() {
                markDailyBonusUsed()
                completionHandler(.defer)
            } else {
                completionHandler(.none)
            }

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func canUseDailyBonus() -> Bool {
        !sharedDefaults.bool(forKey: AppGroupConstants.dailyBonusKey())
    }

    private func markDailyBonusUsed() {
        sharedDefaults.set(true, forKey: AppGroupConstants.dailyBonusKey())
        sharedDefaults.set(true, forKey: AppGroupConstants.pendingBonusKey)
    }
}
