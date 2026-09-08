import SwiftUI

/// A large-touch-target, large-text row used in the agenda list. Designed to be readable and
/// tappable with dirty or gloved hands — big fonts, big buttons, minimal fine print.
struct AppointmentRow: View {
    @Bindable var appointment: Appointment
    var isPastDue: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(TimeFormatter.shortTime(appointment.date))
                    .font(.title2.bold())
                    .foregroundStyle(isPastDue ? .red : .primary)
                Spacer()
                StatusBadge(status: appointment.status, isPastDue: isPastDue)
            }

            Text(appointment.customerName.isEmpty ? "Unnamed customer" : appointment.customerName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text(appointment.vehicleDescription)
                .font(.body)
                .foregroundStyle(.secondary)

            if !appointment.workDescription.isEmpty {
                Text(appointment.workDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if appointment.status == .scheduled && !appointment.customerPhone.isEmpty {
                HStack(spacing: 14) {
                    if let callURL = ContactActions.callURL(phone: appointment.customerPhone) {
                        actionButton(title: "Call", systemImage: "phone.fill", color: .green, url: callURL)
                    }
                    if let textURL = ContactActions.textURL(phone: appointment.customerPhone) {
                        actionButton(title: "Text", systemImage: "message.fill", color: .blue, url: textURL)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private func actionButton(title: String, systemImage: String, color: Color, url: URL) -> some View {
        // `Link` doesn't respond to `.buttonStyle`, so this is styled directly rather than
        // relying on `.buttonStyle(.borderedProminent)` (which would silently no-op here).
        Link(destination: url) {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
        }
    }
}

struct StatusBadge: View {
    let status: AppointmentStatus
    var isPastDue: Bool = false

    var body: some View {
        Text(isPastDue ? "Past Due" : status.label)
            .font(.footnote.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        if isPastDue { return .red }
        switch status {
        case .scheduled: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}
