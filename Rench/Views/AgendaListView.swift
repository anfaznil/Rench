import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct AgendaListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Appointment.date) private var appointments: [Appointment]

    @State private var showingAddSheet = false
    @State private var appointmentToEdit: Appointment?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private var pastDue: [Appointment] {
        appointments.filter { $0.status == .scheduled && $0.date < Date() }
    }

    private var upcomingByDay: [(day: Date, items: [Appointment])] {
        let upcoming = appointments.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
        let grouped = Dictionary(grouping: upcoming) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted().map { day in (day, grouped[day]!.sorted { $0.date < $1.date }) }
    }

    var body: some View {
        List {
            if notificationStatus == .denied {
                NotificationDisabledBanner()
            }

            if pastDue.isEmpty && upcomingByDay.isEmpty {
                EmptyStateView(
                    systemImage: "wrench.and.screwdriver",
                    title: "No Appointments Yet",
                    message: "Tap the + button to add your first appointment."
                )
                .listRowSeparator(.hidden)
            }

            if !pastDue.isEmpty {
                Section {
                    ForEach(pastDue) { appointment in
                        row(for: appointment, isPastDue: true)
                    }
                } header: {
                    Text("Past Due")
                }
            }

            ForEach(upcomingByDay, id: \.day) { group in
                Section {
                    ForEach(group.items) { appointment in
                        row(for: appointment, isPastDue: false)
                    }
                } header: {
                    Text(sectionTitle(for: group.day))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Agenda")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Add Appointment")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AppointmentFormView(mode: .add)
            }
        }
        .sheet(item: $appointmentToEdit) { appointment in
            NavigationStack {
                AppointmentFormView(mode: .edit(appointment))
            }
        }
        .task {
            notificationStatus = await NotificationScheduler.shared.currentAuthorizationStatus()
        }
    }

    @ViewBuilder
    private func row(for appointment: Appointment, isPastDue: Bool) -> some View {
        AppointmentRow(appointment: appointment, isPastDue: isPastDue)
            .contentShape(Rectangle())
            .onTapGesture { appointmentToEdit = appointment }
            .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                delete(appointment)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            if appointment.status == .scheduled {
                Button {
                    appointment.status = .completed
                    appointment.updatedAt = Date()
                    NotificationScheduler.shared.reschedule(for: appointment, context: context)
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .tint(.green)
            }
        }
    }

    private func delete(_ appointment: Appointment) {
        let date = appointment.date
        context.delete(appointment)
        NotificationScheduler.shared.cancelAll(for: appointment, onDate: date, context: context)
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }
        return TimeFormatter.shortDate(day)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct NotificationDisabledBanner: View {
    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders Are Off")
                        .font(.body.weight(.semibold))
                    Text("Turn on notifications to get night-before and one-hour reminders.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}
