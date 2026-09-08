import AppIntents
import Foundation
import SwiftData

/// Voice-driven "add appointment" intent. Every parameter is required (rather than optional) so
/// Siri walks the user through each one as a guided back-and-forth — "What's the customer's
/// name?", "What's the vehicle's make?", and so on — letting an appointment be added hands-free
/// with no screen involved.
struct AddAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Add a Rench Appointment"
    static var description = IntentDescription("Adds a new appointment to your Rench schedule by voice.")

    @Parameter(title: "Customer Name", requestValueDialog: IntentDialog("What's the customer's name?"))
    var customerName: String

    @Parameter(title: "Vehicle Make", requestValueDialog: IntentDialog("What's the make of the vehicle — like Ford or Toyota?"))
    var vehicleMake: String

    @Parameter(title: "Vehicle Model", requestValueDialog: IntentDialog("What's the model?"))
    var vehicleModel: String

    @Parameter(title: "Work Description", requestValueDialog: IntentDialog("What work needs to be done?"))
    var workDescription: String

    @Parameter(title: "Date & Time", requestValueDialog: IntentDialog("When is the appointment?"))
    var date: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Add an appointment for \(\.$customerName)'s \(\.$vehicleMake) \(\.$vehicleModel) at \(\.$date)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = PersistenceController.makeContainer()
        let context = container.mainContext

        let appointment = Appointment(
            date: date,
            customerName: customerName,
            vehicleMake: vehicleMake,
            vehicleModel: vehicleModel,
            workDescription: workDescription
        )
        context.insert(appointment)
        try? context.save()
        NotificationScheduler.shared.reschedule(for: appointment, context: context)

        let time = TimeFormatter.spokenTime(date)
        let sentence = "Got it — added an appointment for \(customerName)'s \(appointment.vehicleDescription) at \(time): \(workDescription)."
        return .result(dialog: IntentDialog(stringLiteral: sentence))
    }
}
