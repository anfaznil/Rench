import AppIntents
import Foundation

struct ScheduleTomorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "What's On My Schedule Tomorrow"
    static var description = IntentDescription("Reads back tomorrow's appointments.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            return .result(dialog: IntentDialog(stringLiteral: "You have no appointments tomorrow."))
        }
        let appointments = AppointmentQuery.appointments(on: tomorrow)
        let sentence = NotificationContentBuilder.spokenScheduleSentence(for: appointments, dayLabel: "tomorrow")
        return .result(dialog: IntentDialog(stringLiteral: sentence))
    }
}
