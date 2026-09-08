import XCTest

final class SchedulingTriggerDateTests: XCTestCase {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = hour; comps.minute = minute
        return calendar.date(from: comps)!
    }

    // MARK: - Night-before trigger

    func testNightBeforeTriggerFiresAtReminderTimeOnThePreviousDay() {
        let appointmentDate = date(2026, 3, 10, 9, 0) // March 10 at 9:00 AM
        let reminderTime = DateComponents(hour: 19, minute: 0) // 7:00 PM
        let now = date(2026, 3, 8, 8, 0) // two days before, well before the trigger

        let trigger = NotificationContentBuilder.nightBeforeTriggerDate(
            forAppointmentDate: appointmentDate,
            reminderTime: reminderTime,
            now: now,
            calendar: calendar
        )

        let expected = date(2026, 3, 9, 19, 0) // March 9 at 7:00 PM
        XCTAssertEqual(trigger, expected)
    }

    func testNightBeforeTriggerReturnsNilWhenReminderMomentAlreadyPassed() {
        // Appointment added same-day, after the configured reminder time has already passed.
        let appointmentDate = date(2026, 3, 10, 9, 0)
        let reminderTime = DateComponents(hour: 19, minute: 0)
        let now = date(2026, 3, 9, 20, 0) // 8:00 PM the night before — an hour after the 7 PM reminder

        let trigger = NotificationContentBuilder.nightBeforeTriggerDate(
            forAppointmentDate: appointmentDate,
            reminderTime: reminderTime,
            now: now,
            calendar: calendar
        )

        XCTAssertNil(trigger)
    }

    func testNightBeforeTriggerRespectsCustomReminderTime() {
        let appointmentDate = date(2026, 3, 10, 9, 0)
        let reminderTime = DateComponents(hour: 6, minute: 30)
        let now = date(2026, 3, 1, 0, 0)

        let trigger = NotificationContentBuilder.nightBeforeTriggerDate(
            forAppointmentDate: appointmentDate,
            reminderTime: reminderTime,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(trigger, date(2026, 3, 9, 6, 30))
    }

    // MARK: - Prior-reminder trigger (configurable lead time)

    func testPriorReminderTriggerIsExactlyLeadMinutesBeforeStartAtDefaultOneHour() {
        let start = date(2026, 3, 10, 14, 0)
        let now = date(2026, 3, 10, 9, 0)

        let trigger = NotificationContentBuilder.priorReminderTriggerDate(forAppointmentStart: start, leadMinutes: 60, now: now)

        XCTAssertEqual(trigger, date(2026, 3, 10, 13, 0))
    }

    func testPriorReminderTriggerRespectsACustomLeadTime() {
        let start = date(2026, 3, 10, 14, 0)
        let now = date(2026, 3, 10, 9, 0)

        XCTAssertEqual(
            NotificationContentBuilder.priorReminderTriggerDate(forAppointmentStart: start, leadMinutes: 30, now: now),
            date(2026, 3, 10, 13, 30)
        )
        XCTAssertEqual(
            NotificationContentBuilder.priorReminderTriggerDate(forAppointmentStart: start, leadMinutes: 120, now: now),
            date(2026, 3, 10, 12, 0)
        )
    }

    func testPriorReminderTriggerReturnsNilWhenLessThanTheLeadTimeRemains() {
        // Appointment created/edited only 30 minutes before it starts, with a 60-minute lead time.
        let start = date(2026, 3, 10, 14, 0)
        let now = date(2026, 3, 10, 13, 30)

        let trigger = NotificationContentBuilder.priorReminderTriggerDate(forAppointmentStart: start, leadMinutes: 60, now: now)

        XCTAssertNil(trigger)
    }

    func testPriorReminderTriggerReturnsNilForPastAppointments() {
        let start = date(2026, 3, 1, 9, 0)
        let now = date(2026, 3, 10, 0, 0)

        let trigger = NotificationContentBuilder.priorReminderTriggerDate(forAppointmentStart: start, leadMinutes: 60, now: now)

        XCTAssertNil(trigger)
    }

    // MARK: - Appointment model derived fields

    func testVehicleDescriptionOmitsMissingFields() {
        let appt = Appointment(date: date(2026, 3, 10, 9, 0), vehicleMake: "Ford", vehicleModel: "", vehicleYear: nil)
        XCTAssertEqual(appt.vehicleDescription, "Ford")
    }

    func testVehicleDescriptionFallsBackWhenEverythingIsBlank() {
        let appt = Appointment(date: date(2026, 3, 10, 9, 0))
        XCTAssertEqual(appt.vehicleDescription, "vehicle")
    }

    func testEndDateAddsEstimatedDuration() {
        let start = date(2026, 3, 10, 9, 0)
        let appt = Appointment(date: start, estimatedDurationMinutes: 90)
        XCTAssertEqual(appt.endDate, start.addingTimeInterval(90 * 60))
    }
}
