import Foundation
import UserNotifications
import SwiftData
import WidgetKit

/// Owns all interaction with `UNUserNotificationCenter`. Appointment mutations call
/// `reschedule(for:previousDate:context:)` / `cancelAll(for:context:)` so notifications never
/// go stale; `rescheduleAll(context:)` does a full resync (app launch, or either the night-before
/// reminder time or the prior-reminder lead time changing in Settings).
@MainActor
final class NotificationScheduler: NSObject {
    static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        // Without this, iOS silently drops every notification whose trigger fires while the
        // app is in the foreground — no banner, no sound, nothing logged. That's almost always
        // the reason a "missing" reminder actually fired and nobody saw it.
        center.delegate = self
    }

    private enum IdentifierPrefix {
        static let nightBeforeDay = "nightBefore-day-"
        static let priorReminder = "priorReminder-appt-"
    }

    // MARK: - Permission

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await currentAuthorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Full resync

    /// Cancels every Rench notification and reschedules from the current appointment list.
    /// Call on app launch and whenever the night-before reminder time or prior-reminder lead
    /// time settings change.
    func rescheduleAll(context: ModelContext) {
        center.removeAllPendingNotificationRequests()

        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { $0.statusRawValue == "scheduled" }
        )
        guard let appointments = try? context.fetch(descriptor) else { return }

        schedulePriorReminder(for: appointments)

        let grouped = Dictionary(grouping: appointments) { Calendar.current.startOfDay(for: $0.date) }
        for (day, dayAppointments) in grouped {
            scheduleNightBefore(day: day, appointments: dayAppointments)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Incremental updates

    /// Call after adding or editing a single appointment. `previousDate` should be the
    /// appointment's date *before* the edit, so the old day's group gets recomputed too if the
    /// appointment moved to a different day.
    func reschedule(for appointment: Appointment, previousDate: Date? = nil, context: ModelContext) {
        removePriorReminder(for: appointment)
        if appointment.status == .scheduled {
            schedulePriorReminder(for: [appointment])
        }
        recomputeNightBefore(forDayContaining: appointment.date, context: context)
        if let previousDate, !Calendar.current.isDate(previousDate, inSameDayAs: appointment.date) {
            recomputeNightBefore(forDayContaining: previousDate, context: context)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Call after deleting an appointment (pass its date before removal from the context).
    func cancelAll(for appointment: Appointment, onDate date: Date, context: ModelContext) {
        removePriorReminder(for: appointment)
        recomputeNightBefore(forDayContaining: date, context: context)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private func recomputeNightBefore(forDayContaining date: Date, context: ModelContext) {
        let day = Calendar.current.startOfDay(for: date)
        let identifier = IdentifierPrefix.nightBeforeDay + Self.dayKey(day)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) else { return }
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate<Appointment> {
                $0.date >= day && $0.date < nextDay && $0.statusRawValue == "scheduled"
            }
        )
        guard let appointments = try? context.fetch(descriptor), !appointments.isEmpty else { return }
        scheduleNightBefore(day: day, appointments: appointments)
    }

    private func scheduleNightBefore(day: Date, appointments: [Appointment]) {
        guard !appointments.isEmpty else { return }
        let reminderTime = AppSettings.reminderTime
        guard let triggerDate = NotificationContentBuilder.nightBeforeTriggerDate(
            forAppointmentDate: day,
            reminderTime: reminderTime
        ) else { return }

        let body = NotificationContentBuilder.combinedNightBeforeSentence(for: appointments)
        let identifier = IdentifierPrefix.nightBeforeDay + Self.dayKey(day)
        schedule(identifier: identifier, title: "Tomorrow's Schedule", body: body, date: triggerDate)
    }

    private func schedulePriorReminder(for appointments: [Appointment]) {
        let leadMinutes = AppSettings.priorReminderMinutes
        for appointment in appointments {
            guard let triggerDate = NotificationContentBuilder.priorReminderTriggerDate(forAppointmentStart: appointment.date, leadMinutes: leadMinutes) else { continue }
            let body = NotificationContentBuilder.priorReminderSentence(for: appointment, leadMinutes: leadMinutes)
            let identifier = IdentifierPrefix.priorReminder + appointment.id.uuidString
            schedule(identifier: identifier, title: "Upcoming Appointment", body: body, date: triggerDate)
        }
    }

    private func removePriorReminder(for appointment: Appointment) {
        center.removePendingNotificationRequests(withIdentifiers: [IdentifierPrefix.priorReminder + appointment.id.uuidString])
    }

    private func schedule(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                #if DEBUG
                print("Rench: failed to schedule notification \(identifier): \(error)")
                #endif
            }
        }
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

extension NotificationScheduler: UNUserNotificationCenterDelegate {
    /// Lets banners/sounds show even while Rench is open — without this, a notification whose
    /// trigger fires while the app is in the foreground is delivered to iOS but never shown to
    /// the user, with no error or log anywhere.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
