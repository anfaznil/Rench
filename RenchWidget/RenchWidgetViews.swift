import SwiftUI
import WidgetKit

/// Home Screen widget content (systemSmall / systemMedium).
struct RenchHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextAppointmentEntry

    var body: some View {
        Group {
            if let appt = entry.appointment {
                content(for: appt)
            } else {
                emptyState
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    @ViewBuilder
    private func content(for appt: AppointmentSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Next Appointment", systemImage: "wrench.and.screwdriver.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(appt.isPastDue ? .red : .accentColor)
                .lineLimit(1)

            Text(TimeFormatter.shortTime(appt.date))
                .font(.title2.bold())

            Text(headline(for: appt))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            if family == .systemMedium, !appt.workDescription.isEmpty {
                Text(appt.workDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private func headline(for appt: AppointmentSummary) -> String {
        appt.customerName.isEmpty ? appt.vehicleDescription : "\(appt.customerName) — \(appt.vehicleDescription)"
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No Upcoming Appointments")
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 0)
        }
    }
}

/// Lock Screen widget content (accessoryRectangular / accessoryInline). The system applies its
/// own monochrome tint to these families, so custom colors are intentionally avoided.
struct RenchLockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextAppointmentEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                if let appt = entry.appointment {
                    Text("\(TimeFormatter.shortTime(appt.date)): \(inlineLabel(for: appt))")
                } else {
                    Text("No appointments")
                }
            default:
                if let appt = entry.appointment {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TimeFormatter.shortTime(appt.date))
                            .font(.headline)
                        Text(inlineLabel(for: appt))
                            .font(.caption)
                            .lineLimit(1)
                    }
                } else {
                    Text("No appointments")
                        .font(.headline)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private func inlineLabel(for appt: AppointmentSummary) -> String {
        appt.customerName.isEmpty ? appt.vehicleDescription : appt.customerName
    }
}
