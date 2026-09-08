import Foundation

/// Formatting helpers shared by the app UI, the widget, App Intents responses, and notification
/// copy, so time strings read consistently everywhere ("2 PM" vs "2:00 PM" etc).
enum TimeFormatter {
    static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Speech-friendly time, e.g. "2 PM" for a whole hour, "2:15 PM" otherwise — reads naturally
    /// when spoken back by Siri or VoiceOver.
    static func spokenTime(_ date: Date, calendar: Calendar = .current) -> String {
        let minute = calendar.component(.minute, from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = minute == 0 ? "h a" : "h:mm a"
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    static func weekdayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// "today" / "tomorrow" / the weekday name, for use inside a sentence.
    static func relativeDayLabel(for date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "today" }
        if calendar.isDateInTomorrow(date) { return "tomorrow" }
        return weekdayName(date)
    }
}
