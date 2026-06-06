import Foundation

/// Psychology-driven copy inspired by Opal, ScreenZen, One Sec, Roots.
enum MindfulCopy {

    enum LimitIntention: String, CaseIterable, Identifiable {
        case endlessScroll = "endless_scroll"
        case boredom = "boredom"
        case habit = "habit"
        case stress = "stress"
        case fomo = "fomo"
        case focus = "focus"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .endlessScroll: return "Безкінечний скрол"
            case .boredom: return "Нудьга"
            case .habit: return "Звичка"
            case .stress: return "Стрес"
            case .fomo: return "Страх пропустити"
            case .focus: return "Відволікає від фокусу"
            }
        }

        var icon: String {
            switch self {
            case .endlessScroll: return "infinity"
            case .boredom: return "cloud"
            case .habit: return "repeat"
            case .stress: return "bolt.heart"
            case .fomo: return "eye"
            case .focus: return "brain.head.profile"
            }
        }

        var intervention: String {
            switch self {
            case .endlessScroll: return "Пауза перед скролом знижує дофаміновий цикл."
            case .boredom: return "Спробуйте 2 хвилини дихання замість додатку."
            case .habit: return "Звички змінюються за 21 день — ви на правильному шляху."
            case .stress: return "Екран рідко вирішує стрес. Поверніться до тіла."
            case .fomo: return "Ви нічого важливого не пропустите."
            case .focus: return "Кожна хвилина тут — хвилина не там, де важливо."
            }
        }
    }

    enum DailyIntention: String, CaseIterable, Identifiable {
        case calm = "calm"
        case productive = "productive"
        case present = "present"
        case sleep = "sleep"
        case social = "social"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .calm: return "Спокійний день"
            case .productive: return "Глибока робота"
            case .present: return "Бути тут і зараз"
            case .sleep: return "Краще заснути"
            case .social: return "Менше порівнянь"
            }
        }

        var icon: String {
            switch self {
            case .calm: return "leaf.fill"
            case .productive: return "target"
            case .present: return "heart.fill"
            case .sleep: return "moon.stars.fill"
            case .social: return "person.2.fill"
            }
        }

        var affirmation: String {
            switch self {
            case .calm: return "Сьогодні я обираю спокій замість стрічки."
            case .productive: return "Мій час — мій найцінніший ресурс."
            case .present: return "Я повертаю увагу до реального життя."
            case .sleep: return "Вечір без екрану — кращий сон."
            case .social: return "Я не зобов'язаний бути онлайн 24/7."
            }
        }
    }

    static func dailyTip(streak: Int, progress: Double) -> String {
        if streak >= 7 {
            return "Тиждень поспіль! Мозок вже звикає до нових меж."
        }
        if progress >= 0.85 {
            return "Зупинись. 5 глибоких вдихів зараз — краще ніж ще 5 хв у стрічці."
        }
        if progress < 0.3 {
            return "Чудовий старт дня. Збережи цей темп."
        }
        return "Кожне «ні» додатку — це «так» тому, що справді важливо."
    }

    static let breathePrompts: [String] = [
        "Вдих…",
        "Затримка…",
        "Видих…",
        "Ви в контролі."
    ]

    static func focusSessionStartMessage(minutes: Int) -> String {
        "Наступні \(minutes) хв — тільки для вас. Сповістлення зачекають."
    }
}

enum HabitMilestone: Int, CaseIterable, Comparable {
    case starter = 1
    case threeDays = 3
    case week = 7
    case twoWeeks = 14
    case month = 30
    case deepRoots = 60
    case mastery = 100

    static func < (lhs: HabitMilestone, rhs: HabitMilestone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .starter: return "Перший крок"
        case .threeDays: return "3 дні поспіль"
        case .week: return "Тиждень сили"
        case .twoWeeks: return "2 тижні звички"
        case .month: return "Місяць фокусу"
        case .deepRoots: return "Глибокі корені"
        case .mastery: return "Майстер уваги"
        }
    }

    var subtitle: String {
        switch self {
        case .starter: return "Ви почали відновлювати контроль."
        case .threeDays: return "Дофаміновий цикл вже слабшає."
        case .week: return "Серйозна звичка вже формується."
        case .twoWeeks: return "Ваш мозок очікує нових меж."
        case .month: return "Це вже частина вашої ідентичності."
        case .deepRoots: return "Як дерево в Roots — міцний фундамент."
        case .mastery: return "Ви в топ-1% користувачів уваги."
        }
    }

    var icon: String {
        switch self {
        case .starter: return "leaf.fill"
        case .threeDays: return "flame.fill"
        case .week: return "star.fill"
        case .twoWeeks: return "tree.fill"
        case .month: return "crown.fill"
        case .deepRoots: return "mountain.2.fill"
        case .mastery: return "sparkles"
        }
    }

    static func highestReached(streak: Int) -> HabitMilestone? {
        allCases.reversed().first { streak >= $0.rawValue }
    }

    static func newlyReached(previous: Int, current: Int) -> HabitMilestone? {
        guard current > previous else { return nil }
        return allCases.first { $0.rawValue > previous && $0.rawValue <= current }
    }
}
