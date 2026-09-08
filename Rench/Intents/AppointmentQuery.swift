import Foundation
import SwiftData

/// Fetch helpers used by App Intents, which run outside the SwiftUI view hierarchy and so need
/// their own `ModelContainer` handle onto the same App-Group-backed store.
enum AppointmentQuery {
    @MainActor
    static func nextAppointment(after date: Date = Date()) -> Appointment? {
        let context = PersistenceController.makeContainer().mainContext
        var descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate<Appointment> { $0.statusRawValue == "scheduled" && $0.date >= date },
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    @MainActor
    static func appointments(on day: Date, calendar: Calendar = .current) -> [Appointment] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let context = PersistenceController.makeContainer().mainContext
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate<Appointment> { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
