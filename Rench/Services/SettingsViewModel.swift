import Foundation
import Combine

/// SwiftUI-facing wrapper over `AppSettings` (App-Group `UserDefaults`). Views bind to the
/// `@Published` properties; call `persist()` to write edits back and learn whether the
/// reminder time changed (so the caller can trigger a notification resync).
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var userName: String
    @Published var businessName: String
    @Published var reminderHour: Int
    @Published var reminderMinute: Int
    @Published var priorReminderMinutes: Int
    @Published var hasSeenSpokenContentPrompt: Bool
    @Published var hasSeenShortcutsInfo: Bool

    init() {
        hasCompletedOnboarding = AppSettings.hasCompletedOnboarding
        userName = AppSettings.userName
        businessName = AppSettings.businessName
        let time = AppSettings.reminderTime
        reminderHour = time.hour ?? 19
        reminderMinute = time.minute ?? 0
        priorReminderMinutes = AppSettings.priorReminderMinutes
        hasSeenSpokenContentPrompt = AppSettings.hasSeenSpokenContentPrompt
        hasSeenShortcutsInfo = AppSettings.hasSeenShortcutsInfo
    }

    var reminderTimeAsDate: Date {
        get {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = reminderHour
            comps.minute = reminderMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = comps.hour ?? 19
            reminderMinute = comps.minute ?? 0
        }
    }

    func completeOnboarding(name: String, businessName: String, reminderTime: Date) {
        userName = name
        self.businessName = businessName
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = comps.hour ?? 19
        reminderMinute = comps.minute ?? 0
        hasCompletedOnboarding = true
        persist()
    }

    func markSpokenContentPromptSeen() {
        hasSeenSpokenContentPrompt = true
        AppSettings.hasSeenSpokenContentPrompt = true
    }

    func markShortcutsInfoSeen() {
        hasSeenShortcutsInfo = true
        AppSettings.hasSeenShortcutsInfo = true
    }

    /// Writes all fields back to shared UserDefaults. Returns `true` if a setting that affects
    /// scheduled notifications (the night-before reminder time or the prior-reminder lead time)
    /// changed, so callers know to resync.
    @discardableResult
    func persist() -> Bool {
        let oldReminder = AppSettings.reminderTime
        let oldLeadMinutes = AppSettings.priorReminderMinutes

        AppSettings.hasCompletedOnboarding = hasCompletedOnboarding
        AppSettings.userName = userName
        AppSettings.businessName = businessName
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = reminderMinute
        AppSettings.reminderTime = comps
        AppSettings.priorReminderMinutes = priorReminderMinutes

        let reminderTimeChanged = oldReminder.hour != reminderHour || oldReminder.minute != reminderMinute
        let leadMinutesChanged = oldLeadMinutes != priorReminderMinutes
        return reminderTimeChanged || leadMinutesChanged
    }
}
