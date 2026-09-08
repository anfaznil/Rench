import AppIntents

/// Registers Rench's App Intents as Siri/Shortcuts App Shortcuts. Every default phrase includes
/// "Rench" per the product spec; users can record their own phrase per-shortcut from the
/// Shortcuts app (explained in ShortcutsInfoView).
struct RenchShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextAppointmentIntent(),
            phrases: [
                "Ask \(.applicationName) what's my next appointment",
                "Ask \(.applicationName) for my next appointment",
                "What's my next appointment in \(.applicationName)"
            ],
            shortTitle: "Next Appointment",
            systemImageName: "wrench.and.screwdriver"
        )
        AppShortcut(
            intent: ScheduleTodayIntent(),
            phrases: [
                "Ask \(.applicationName) what's on my schedule today",
                "Ask \(.applicationName) what's on my schedule",
                "What's on my schedule today in \(.applicationName)"
            ],
            shortTitle: "Today's Schedule",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: ScheduleTomorrowIntent(),
            phrases: [
                "Ask \(.applicationName) what's on my schedule tomorrow",
                "What's on my schedule tomorrow in \(.applicationName)"
            ],
            shortTitle: "Tomorrow's Schedule",
            systemImageName: "calendar.badge.clock"
        )
        // Note: App Shortcut phrases can only embed AppEntity/AppEnum parameters, not a raw
        // Date — so `day` isn't referenced in the phrase text below. Siri still asks the user
        // which day via the framework's built-in parameter prompt when this shortcut is invoked.
        AppShortcut(
            intent: ScheduleForDayIntent(),
            phrases: [
                "Ask \(.applicationName) what's my schedule for a day",
                "Ask \(.applicationName) for my schedule for a specific day"
            ],
            shortTitle: "Schedule For a Day",
            systemImageName: "calendar.circle"
        )
        AppShortcut(
            intent: AddAppointmentIntent(),
            phrases: [
                "Add an appointment in \(.applicationName)",
                "Ask \(.applicationName) to add an appointment",
                "Create a new appointment in \(.applicationName)"
            ],
            shortTitle: "Add Appointment",
            systemImageName: "plus.circle"
        )
    }
}
