import WidgetKit
import SwiftData
import Foundation

struct NextAppointmentEntry: TimelineEntry {
    let date: Date
    let appointment: AppointmentSummary?
}

struct NextAppointmentProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextAppointmentEntry {
        NextAppointmentEntry(date: Date(), appointment: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextAppointmentEntry) -> Void) {
        completion(NextAppointmentEntry(date: Date(), appointment: context.isPreview ? .placeholder : fetchNext()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextAppointmentEntry>) -> Void) {
        let now = Date()
        let next = fetchNext()
        let entry = NextAppointmentEntry(date: now, appointment: next)

        // Refresh again when the shown appointment starts (so the widget advances to whatever
        // comes after it) or in an hour, whichever comes first — keeps the widget from ever
        // showing a stale "next" appointment for too long even without an explicit reload.
        let candidate = next.map { min($0.date, now.addingTimeInterval(3600)) } ?? now.addingTimeInterval(3600)
        let nextRefresh = max(candidate, now.addingTimeInterval(60))
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    /// Not `@MainActor` — `TimelineProvider`'s methods are non-isolated, so this uses a plain
    /// background `ModelContext` rather than `container.mainContext`.
    private func fetchNext() -> AppointmentSummary? {
        let container = PersistenceController.makeContainer()
        let context = ModelContext(container)
        let now = Date()
        var descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate<Appointment> { $0.statusRawValue == "scheduled" && $0.date >= now },
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1
        guard let appointment = try? context.fetch(descriptor).first else { return nil }
        return AppointmentSummary(appointment: appointment)
    }
}
