import Foundation

/// A plain, Codable-friendly snapshot of the fields the widget needs. Deliberately not the
/// SwiftData `Appointment` itself — widget timeline entries shouldn't hold onto model objects
/// tied to a particular `ModelContainer`/context lifecycle.
struct AppointmentSummary: Identifiable {
    let id: UUID
    let date: Date
    let customerName: String
    let vehicleDescription: String
    let workDescription: String
    let isPastDue: Bool

    init(id: UUID, date: Date, customerName: String, vehicleDescription: String, workDescription: String, isPastDue: Bool) {
        self.id = id
        self.date = date
        self.customerName = customerName
        self.vehicleDescription = vehicleDescription
        self.workDescription = workDescription
        self.isPastDue = isPastDue
    }

    init(appointment: Appointment) {
        self.id = appointment.id
        self.date = appointment.date
        self.customerName = appointment.customerName
        self.vehicleDescription = appointment.vehicleDescription
        self.workDescription = appointment.workDescription
        self.isPastDue = appointment.status == .scheduled && appointment.date < Date()
    }

    static let placeholder = AppointmentSummary(
        id: UUID(),
        date: Date(),
        customerName: "Jane Doe",
        vehicleDescription: "2020 Honda Civic",
        workDescription: "Oil change",
        isPastDue: false
    )
}
