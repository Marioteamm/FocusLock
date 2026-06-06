// Конфігурація екрану блокування Shield
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private var sharedDefaults: UserDefaults { AppGroupConstants.groupDefaults }

    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        buildConfiguration(name: application.localizedDisplayName ?? "Додаток")
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        buildConfiguration(name: application.localizedDisplayName ?? "Додаток")
    }

    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        buildConfiguration(name: webDomain.domain ?? "Сайт")
    }

    private func buildConfiguration(name: String) -> ShieldConfiguration {
        let bonusUsed = sharedDefaults.bool(forKey: AppGroupConstants.dailyBonusKey())
        let strict = sharedDefaults.bool(forKey: AppGroupConstants.strictModeKey)

        let primaryLabel: ShieldConfiguration.Label? = (bonusUsed || strict)
            ? nil
            : ShieldConfiguration.Label(text: "Додати 15 хвилин", color: .white)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 0.97),
            icon: buildIcon(),
            title: ShieldConfiguration.Label(
                text: "Ліміт досягнуто",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: strict
                    ? "Суворий режим активний.\nПоверніться завтра або займіться фокусом."
                    : "Ви використали денний ліміт для \(name).\nЗробіть паузу — мозок подякує.",
                color: UIColor(white: 0.65, alpha: 1.0)
            ),
            primaryButtonLabel: primaryLabel,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Закрити",
                color: UIColor(white: 0.55, alpha: 1.0)
            )
        )
    }

    private func buildIcon() -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .medium)
        return UIImage(systemName: "lock.circle.fill", withConfiguration: config)?
            .withTintColor(
                UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),
                renderingMode: .alwaysOriginal
            )
    }
}
