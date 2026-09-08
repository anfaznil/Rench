import AppIntents

struct NextAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "What's My Next Appointment"
    static var description = IntentDescription("Tells you your next upcoming appointment.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let appointment = AppointmentQuery.nextAppointment()
        let sentence = NotificationContentBuilder.spokenNextAppointmentSentence(for: appointment)
        return .result(dialog: IntentDialog(stringLiteral: sentence))
    }
}
