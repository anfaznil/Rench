import Foundation

/// Thin, static accessor over App-Group-shared `UserDefaults`. Kept separate from any
/// SwiftUI/ObservableObject wrapper so it's usable from the widget extension, App Intents,
/// and the notification scheduler without pulling in Combine.
enum AppSettings {
    private static var defaults: UserDefaults { AppGroup.sharedDefaults }

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userName = "userName"
        static let businessName = "businessName"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
        static let priorReminderMinutes = "priorReminderMinutes"
        static let hasSeenSpokenContentPrompt = "hasSeenSpokenContentPrompt"
        static let hasSeenShortcutsInfo = "hasSeenShortcutsInfo"
    }

    static var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    static var userName: String {
        get { defaults.string(forKey: Keys.userName) ?? "" }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }

    static var businessName: String {
        get { defaults.string(forKey: Keys.businessName) ?? "" }
        set { defaults.set(newValue, forKey: Keys.businessName) }
    }

    /// Defaults to 7:00 PM per the product spec.
    static var reminderTime: DateComponents {
        get {
            let hour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 19
            let minute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            return comps
        }
        set {
            defaults.set(newValue.hour ?? 19, forKey: Keys.reminderHour)
            defaults.set(newValue.minute ?? 0, forKey: Keys.reminderMinute)
        }
    }

    /// How long before an appointment's start time the "prior" reminder notification fires.
    /// Defaults to 60 minutes per the product spec; editable in Settings.
    static var priorReminderMinutes: Int {
        get { defaults.object(forKey: Keys.priorReminderMinutes) as? Int ?? 60 }
        set { defaults.set(newValue, forKey: Keys.priorReminderMinutes) }
    }

    static var hasSeenSpokenContentPrompt: Bool {
        get { defaults.bool(forKey: Keys.hasSeenSpokenContentPrompt) }
        set { defaults.set(newValue, forKey: Keys.hasSeenSpokenContentPrompt) }
    }

    static var hasSeenShortcutsInfo: Bool {
        get { defaults.bool(forKey: Keys.hasSeenShortcutsInfo) }
        set { defaults.set(newValue, forKey: Keys.hasSeenShortcutsInfo) }
    }
}
