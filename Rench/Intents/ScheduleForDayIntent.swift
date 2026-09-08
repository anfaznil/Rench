import AppIntents
import Foundation

struct ScheduleForDayIntent: AppIntent {
    static var title: LocalizedStringResource = "What's My Schedule For a Day"
    static var description = IntentDescription("Reads back the appointments for a specific day.")

    @Parameter(title: "Day")
    var day: Date

    static var parameterSummary: some ParameterSummary {
        Summary("What's my schedule for \(\.$day)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let appointments = AppointmentQuery.appointments(on: day)
        let relative = TimeFormatter.relativeDayLabel(for: day)
        let dayLabel = (relative == "today" || relative == "tomorrow") ? relative : "on \(relative)"
        let sentence = NotificationContentBuilder.spokenScheduleSentence(for: appointments, dayLabel: dayLabel)
        return .result(dialog: IntentDialog(stringLiteral: sentence))
    }
}
