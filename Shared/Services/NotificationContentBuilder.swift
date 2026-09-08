import Foundation

/// Pure functions for building notification/spoken-response sentences and their trigger dates.
/// Deliberately free of `UNUserNotificationCenter` so this logic is trivially unit-testable;
/// `NotificationScheduler` (app target only) wraps this with the actual scheduling calls.
enum NotificationContentBuilder {

    // MARK: - Notification sentences

    /// e.g. "Tomorrow at 9:00 AM: oil change and brake inspection for John's 2018 Ford F-150."
    static func nightBeforeSentence(for appointment: Appointment) -> String {
        let time = TimeFormatter.shortTime(appointment.date)
        return "Tomorrow at \(time): \(jobPhrase(for: appointment)) for \(customerVehiclePhrase(for: appointment))."
    }

    /// Combines every appointment on a given day into one readable summary. Callers decide the
    /// threshold for when to use this vs. individual notifications (see `shouldCombine`).
    static func combinedNightBeforeSentence(for appointments: [Appointment]) -> String {
        let sorted = appointments.sorted { $0.date < $1.date }
        guard let first = sorted.first else { return "You have no appointments tomorrow." }
        if sorted.count == 1 { return nightBeforeSentence(for: first) }
        let items = sorted.map { appt in
            "\(TimeFormatter.shortTime(appt.date)) — \(jobPhrase(for: appt)) for \(customerVehiclePhrase(for: appt))"
        }
        return "You have \(sorted.count) appointments tomorrow: \(items.joined(separator: "; "))."
    }

    /// e.g. "Reminder: appointment in 1 hour — transmission check for a 2020 Honda Civic." The
    /// lead time is user-configurable (see `AppSettings.priorReminderMinutes`), so this reads
    /// naturally at any value: "in 30 minutes", "in 1 hour", "in 1 hour 30 minutes", etc.
    static func priorReminderSentence(for appointment: Appointment, leadMinutes: Int) -> String {
        "Reminder: appointment in \(naturalDuration(minutes: leadMinutes)) — \(jobPhrase(for: appointment)) for \(vehiclePhrase(for: appointment))."
    }

    /// "45 minutes", "1 hour", "1 hour 30 minutes" — never "1 hours" or "0 hour 45 minutes".
    static func naturalDuration(minutes: Int) -> String {
        guard minutes >= 60 else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        let hourPart = "\(hours) hour\(hours == 1 ? "" : "s")"
        guard remainder > 0 else { return hourPart }
        return "\(hourPart) \(remainder) minute\(remainder == 1 ? "" : "s")"
    }

    // MARK: - Spoken (App Intents / Siri) sentences

    static func spokenNextAppointmentSentence(for appointment: Appointment?) -> String {
        guard let appointment else {
            return "You don't have any upcoming appointments."
        }
        let time = TimeFormatter.spokenTime(appointment.date)
        return "Your next appointment is at \(time): \(jobPhrase(for: appointment)) for \(vehiclePhrase(for: appointment))."
    }

    /// `dayLabel` should read naturally after "you have N appointments ___", e.g. "today",
    /// "tomorrow", or "on Thursday".
    static func spokenScheduleSentence(for appointments: [Appointment], dayLabel: String) -> String {
        let scheduled = appointments.filter { $0.status == .scheduled }.sorted { $0.date < $1.date }
        guard !scheduled.isEmpty else {
            return "You have no appointments \(dayLabel)."
        }
        if scheduled.count == 1 {
            let appt = scheduled[0]
            return "You have one appointment \(dayLabel), at \(TimeFormatter.spokenTime(appt.date)): \(jobPhrase(for: appt)) for \(vehiclePhrase(for: appt))."
        }
        let items = scheduled.map { appt in
            "\(TimeFormatter.spokenTime(appt.date)) — \(jobPhrase(for: appt)) for \(vehiclePhrase(for: appt))"
        }
        return "You have \(scheduled.count) appointments \(dayLabel): \(items.joined(separator: "; "))."
    }

    // MARK: - Phrase helpers

    static func jobPhrase(for appointment: Appointment) -> String {
        let desc = appointment.workDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return desc.isEmpty ? "your appointment" : desc
    }

    static func vehiclePhrase(for appointment: Appointment) -> String {
        "a \(appointment.vehicleDescription)"
    }

    static func customerVehiclePhrase(for appointment: Appointment) -> String {
        let name = appointment.customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return vehiclePhrase(for: appointment) }
        return "\(name)'s \(appointment.vehicleDescription)"
    }

    // MARK: - Trigger date computation

    /// The moment the night-before digest for `appointmentDate` should fire: the configured
    /// reminder time on the previous calendar day. Returns `nil` if that moment is already past
    /// (e.g. the appointment was added same-day, after the reminder time).
    static func nightBeforeTriggerDate(
        forAppointmentDate appointmentDate: Date,
        reminderTime: DateComponents,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        let day = calendar.startOfDay(for: appointmentDate)
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: day) else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        comps.hour = reminderTime.hour ?? 19
        comps.minute = reminderTime.minute ?? 0
        comps.second = 0
        guard let trigger = calendar.date(from: comps), trigger > now else { return nil }
        return trigger
    }

    /// `leadMinutes` before the appointment's start time. Returns `nil` if that moment has
    /// already passed (e.g. the appointment starts sooner than the configured lead time when
    /// it's created or edited).
    static func priorReminderTriggerDate(forAppointmentStart start: Date, leadMinutes: Int, now: Date = Date()) -> Date? {
        let trigger = start.addingTimeInterval(-Double(leadMinutes) * 60)
        return trigger > now ? trigger : nil
    }

    /// Product rule: 2 or more appointments on the same day get a single combined summary
    /// notification instead of one notification per appointment.
    static func shouldCombine(appointmentCount: Int) -> Bool {
        appointmentCount >= 2
    }
}
