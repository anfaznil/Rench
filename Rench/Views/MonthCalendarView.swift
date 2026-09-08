import SwiftUI
import SwiftData

struct MonthCalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Appointment.date) private var appointments: [Appointment]

    @State private var visibleMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var appointmentToEdit: Appointment?
    @State private var showingAddSheet = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var appointmentsByDay: [Date: [Appointment]] {
        Dictionary(grouping: appointments) { calendar.startOfDay(for: $0.date) }
    }

    private var selectedDayAppointments: [Appointment] {
        (appointmentsByDay[selectedDay] ?? []).sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader

            weekdayHeader

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInGrid, id: \.self) { day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)

            Divider().padding(.top, 12)

            List {
                if selectedDayAppointments.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.badge.checkmark",
                        title: "Nothing Scheduled",
                        message: "No appointments on \(TimeFormatter.shortDate(selectedDay))."
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(selectedDayAppointments) { appointment in
                        AppointmentRow(appointment: appointment, isPastDue: appointment.status == .scheduled && appointment.date < Date())
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
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .accessibilityLabel("Add Appointment")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack { AppointmentFormView(mode: .add) }
        }
        .sheet(item: $appointmentToEdit) { appointment in
            NavigationStack { AppointmentFormView(mode: .edit(appointment)) }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left").font(.title2)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(monthTitle)
                .font(.title2.weight(.semibold))
            Spacer()
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right").font(.title2)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func dayCell(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let hasAppointments = !(appointmentsByDay[day] ?? []).isEmpty
        let hasPastDue = (appointmentsByDay[day] ?? []).contains { $0.status == .scheduled && $0.date < Date() }

        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.body.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : .primary)
                Circle()
                    .fill(hasPastDue ? .red : .accentColor)
                    .frame(width: 6, height: 6)
                    .opacity(hasAppointments ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.15) : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: visibleMonth)
    }

    private var shortWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }

    /// Full weeks (including leading/trailing blanks) covering the visible month.
    private var daysInGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstOfMonth = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        var day = firstOfMonth
        while day < monthInterval.end {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private func changeMonth(by delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = newMonth
        }
    }

    private func delete(_ appointment: Appointment) {
        let date = appointment.date
        context.delete(appointment)
        NotificationScheduler.shared.cancelAll(for: appointment, onDate: date, context: context)
    }
}
