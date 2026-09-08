import AppIntents
import Foundation

struct ScheduleTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "What's On My Schedule Today"
    static var description = IntentDescription("Reads back today's appointments.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let appointments = AppointmentQuery.appointments(on: Date())
        let sentence = NotificationContentBuilder.spokenScheduleSentence(for: appointments, dayLabel: "today")
        return .result(dialog: IntentDialog(stringLiteral: sentence))
    }
}
