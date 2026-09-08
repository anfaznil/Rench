import Foundation
import SwiftData

enum AppointmentStatus: String, Codable, CaseIterable, Sendable {
    case scheduled
    case completed
    case cancelled

    var label: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

/// A single appointment on the tech's schedule.
///
/// All stored properties carry inline default values (or are Optional) because SwiftData's
/// CloudKit integration requires every attribute to be able to resolve a value when a peer
/// device syncs a schema it doesn't yet fully recognize.
@Model
final class Appointment {
    /// Stable identity used for notification identifiers and App Intents entities, independent
    /// of SwiftData's internal persistent identifier.
    var id: UUID = UUID()

    /// Combined date + start time of the appointment.
    var date: Date = Date()
    var estimatedDurationMinutes: Int = 60

    var customerName: String = ""
    var customerPhone: String = ""

    var vehicleMake: String = ""
    var vehicleModel: String = ""
    var vehicleYear: Int?

    var workDescription: String = ""
    var statusRawValue: String = AppointmentStatus.scheduled.rawValue
    var notes: String = ""

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRawValue) ?? .scheduled }
        set { statusRawValue = newValue.rawValue }
    }

    var endDate: Date {
        date.addingTimeInterval(TimeInterval(estimatedDurationMinutes * 60))
    }

    /// e.g. "2018 Ford F-150" — degrades gracefully if some fields are blank.
    var vehicleDescription: String {
        var parts: [String] = []
        if let vehicleYear { parts.append(String(vehicleYear)) }
        let make = vehicleMake.trimmingCharacters(in: .whitespacesAndNewlines)
        if !make.isEmpty { parts.append(make) }
        let model = vehicleModel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !model.isEmpty { parts.append(model) }
        return parts.isEmpty ? "vehicle" : parts.joined(separator: " ")
    }

    init(
        date: Date = Date(),
        estimatedDurationMinutes: Int = 60,
        customerName: String = "",
        customerPhone: String = "",
        vehicleMake: String = "",
        vehicleModel: String = "",
        vehicleYear: Int? = nil,
        workDescription: String = "",
        status: AppointmentStatus = .scheduled,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.vehicleMake = vehicleMake
        self.vehicleModel = vehicleModel
        self.vehicleYear = vehicleYear
        self.workDescription = workDescription
        self.statusRawValue = status.rawValue
        self.notes = notes
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
