import Foundation

enum AppError: LocalizedError, Identifiable, Equatable {
    case authorizationDenied
    case authorizationFailed(String)
    case monitoringFailed(String)
    case persistenceFailed(String)
    case noAppsSelected
    case sessionAlreadyActive
    case generic(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Дозвіл Screen Time не надано. Увімкніть його в Налаштуваннях."
        case .authorizationFailed(let msg):
            return "Помилка авторизації: \(msg)"
        case .monitoringFailed(let msg):
            return "Не вдалося запустити моніторинг: \(msg)"
        case .persistenceFailed(let msg):
            return "Помилка збереження: \(msg)"
        case .noAppsSelected:
            return "Спочатку оберіть хоча б один додаток."
        case .sessionAlreadyActive:
            return "Фокус-сесія вже активна."
        case .generic(let msg):
            return msg
        }
    }
}

enum ViewLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(AppError)

    static func == (lhs: ViewLoadState, rhs: ViewLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}
