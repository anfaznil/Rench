import XCTest

// Appointment / NotificationContentBuilder live in the Shared/ folder, which this test target
// compiles directly (see project.yml) — no @testable import of the app target needed.
final class NotificationContentBuilderTests: XCTestCase {

    private func makeAppointment(
        date: Date,
        customerName: String = "John",
        make: String = "Ford",
        model: String = "F-150",
        year: Int? = 2018,
        work: String = "oil change and brake inspection"
    ) -> Appointment {
        Appointment(
            date: date,
            customerName: customerName,
            vehicleMake: make,
            vehicleModel: model,
            vehicleYear: year,
            workDescription: work
        )
    }

    private func date(hour: Int, minute: Int = 0, daysFromNow: Int = 0, calendar: Calendar = .current) -> Date {
        let base = calendar.date(byAdding: .day, value: daysFromNow, to: Date())!
        var comps = calendar.dateComponents([.year, .month, .day], from: base)
        comps.hour = hour
        comps.minute = minute
        return calendar.date(from: comps)!
    }

    // MARK: - Sentence formatting

    func testNightBeforeSentenceIsAFullNaturalSentence() {
        let appt = makeAppointment(date: date(hour: 9), customerName: "John")
        let sentence = NotificationContentBuilder.nightBeforeSentence(for: appt)
        XCTAssertEqual(sentence, "Tomorrow at 9:00 AM: oil change and brake inspection for John's 2018 Ford F-150.")
    }

    func testPriorReminderSentenceMatchesSpecFormatAtDefaultOneHour() {
        let appt = makeAppointment(date: date(hour: 14), make: "Honda", model: "Civic", year: 2020, work: "transmission check")
        let sentence = NotificationContentBuilder.priorReminderSentence(for: appt, leadMinutes: 60)
        XCTAssertEqual(sentence, "Reminder: appointment in 1 hour — transmission check for a 2020 Honda Civic.")
    }

    func testPriorReminderSentenceReadsNaturallyAtOtherLeadTimes() {
        let appt = makeAppointment(date: date(hour: 14), make: "Honda", model: "Civic", year: 2020, work: "transmission check")
        XCTAssertEqual(
            NotificationContentBuilder.priorReminderSentence(for: appt, leadMinutes: 30),
            "Reminder: appointment in 30 minutes — transmission check for a 2020 Honda Civic."
        )
        XCTAssertEqual(
            NotificationContentBuilder.priorReminderSentence(for: appt, leadMinutes: 90),
            "Reminder: appointment in 1 hour 30 minutes — transmission check for a 2020 Honda Civic."
        )
    }

    func testNaturalDurationFormatting() {
        XCTAssertEqual(NotificationContentBuilder.naturalDuration(minutes: 1), "1 minute")
        XCTAssertEqual(NotificationContentBuilder.naturalDuration(minutes: 15), "15 minutes")
        XCTAssertEqual(NotificationContentBuilder.naturalDuration(minutes: 60), "1 hour")
        XCTAssertEqual(NotificationContentBuilder.naturalDuration(minutes: 90), "1 hour 30 minutes")
        XCTAssertEqual(NotificationContentBuilder.naturalDuration(minutes: 120), "2 hours")
        XCTAssertEqual(NotificationContentBuilder.naturalDuration(minutes: 150), "2 hours 30 minutes")
    }

    func testCombinedNightBeforeSentenceListsEveryAppointment() {
        let a = makeAppointment(date: date(hour: 9), customerName: "John", work: "oil change")
        let b = makeAppointment(date: date(hour: 13), customerName: "Amy", make: "Toyota", model: "Camry", year: 2015, work: "brake pads")
        let sentence = NotificationContentBuilder.combinedNightBeforeSentence(for: [b, a])
        XCTAssertTrue(sentence.hasPrefix("You have 2 appointments tomorrow:"))
        XCTAssertTrue(sentence.contains("9:00 AM — oil change for John's 2018 Ford F-150"))
        XCTAssertTrue(sentence.contains("1:00 PM — brake pads for Amy's 2015 Toyota Camry"))
    }

    func testSpokenNextAppointmentSentenceHandlesNoAppointments() {
        let sentence = NotificationContentBuilder.spokenNextAppointmentSentence(for: nil)
        XCTAssertEqual(sentence, "You don't have any upcoming appointments.")
    }

    func testSpokenNextAppointmentSentenceReadsNaturally() {
        let appt = makeAppointment(date: date(hour: 14), make: "Toyota", model: "Camry", year: 2015, work: "brake pads")
        let sentence = NotificationContentBuilder.spokenNextAppointmentSentence(for: appt)
        XCTAssertEqual(sentence, "Your next appointment is at 2 PM: brake pads for a 2015 Toyota Camry.")
    }

    func testSpokenScheduleSentenceHandlesEmptyDay() {
        let sentence = NotificationContentBuilder.spokenScheduleSentence(for: [], dayLabel: "today")
        XCTAssertEqual(sentence, "You have no appointments today.")
    }

    func testSpokenScheduleSentenceIgnoresCancelledAppointments() {
        let cancelled = Appointment(date: date(hour: 9), customerName: "Skip", status: .cancelled)
        let sentence = NotificationContentBuilder.spokenScheduleSentence(for: [cancelled], dayLabel: "today")
        XCTAssertEqual(sentence, "You have no appointments today.")
    }

    // MARK: - Combine threshold (2+ appointments -> single summary, per product decision)

    func testShouldCombineIsFalseForOneAppointment() {
        XCTAssertFalse(NotificationContentBuilder.shouldCombine(appointmentCount: 1))
    }

    func testShouldCombineIsTrueForTwoOrMoreAppointments() {
        XCTAssertTrue(NotificationContentBuilder.shouldCombine(appointmentCount: 2))
        XCTAssertTrue(NotificationContentBuilder.shouldCombine(appointmentCount: 5))
    }

    // MARK: - Blank-field fallbacks

    func testCustomerVehiclePhraseFallsBackWhenNameIsBlank() {
        let appt = makeAppointment(date: date(hour: 9), customerName: "  ")
        XCTAssertEqual(NotificationContentBuilder.customerVehiclePhrase(for: appt), "a 2018 Ford F-150")
    }

    func testJobPhraseFallsBackWhenDescriptionIsBlank() {
        let appt = makeAppointment(date: date(hour: 9), work: "")
        XCTAssertEqual(NotificationContentBuilder.jobPhrase(for: appt), "your appointment")
    }
}
