import SwiftUI
import SwiftData

enum AppointmentFormMode {
    case add
    case edit(Appointment)
}

/// Add/edit form. Large fields and generous spacing per the "usable with gloved hands" requirement.
struct AppointmentFormView: View {
    let mode: AppointmentFormMode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var durationMinutes: Int
    @State private var customerName: String
    @State private var customerPhone: String
    @State private var vehicleMake: String
    @State private var vehicleModel: String
    @State private var vehicleYearText: String
    @State private var workDescription: String
    @State private var status: AppointmentStatus
    @State private var notes: String

    @State private var showingDeleteConfirmation = false

    private let durationOptions = [15, 30, 45, 60, 90, 120, 180, 240]

    init(mode: AppointmentFormMode) {
        self.mode = mode
        let existing: Appointment? = {
            if case .edit(let appointment) = mode { return appointment }
            return nil
        }()
        _date = State(initialValue: existing?.date ?? Self.nextRoundHour())
        _durationMinutes = State(initialValue: existing?.estimatedDurationMinutes ?? 60)
        _customerName = State(initialValue: existing?.customerName ?? "")
        _customerPhone = State(initialValue: existing?.customerPhone ?? "")
        _vehicleMake = State(initialValue: existing?.vehicleMake ?? "")
        _vehicleModel = State(initialValue: existing?.vehicleModel ?? "")
        _vehicleYearText = State(initialValue: existing?.vehicleYear.map(String.init) ?? "")
        _workDescription = State(initialValue: existing?.workDescription ?? "")
        _status = State(initialValue: existing?.status ?? .scheduled)
        _notes = State(initialValue: existing?.notes ?? "")
    }

    private static func nextRoundHour() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let rounded = calendar.date(bySetting: .minute, value: 0, of: now) ?? now
        return calendar.date(byAdding: .hour, value: 1, to: rounded) ?? now
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        Form {
            Section("When") {
                DatePicker("Date & Time", selection: $date)
                    .font(.title3)
                Picker("Duration", selection: $durationMinutes) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        Text(durationLabel(minutes)).tag(minutes)
                    }
                }
                .font(.title3)
            }

            Section("Customer") {
                TextField("Name", text: $customerName)
                    .font(.title3)
                TextField("Phone Number", text: $customerPhone)
                    .font(.title3)
                    .keyboardType(.phonePad)
            }

            Section("Vehicle") {
                TextField("Make (e.g. Ford)", text: $vehicleMake)
                    .font(.title3)
                TextField("Model (e.g. F-150)", text: $vehicleModel)
                    .font(.title3)
                TextField("Year", text: $vehicleYearText)
                    .font(.title3)
                    .keyboardType(.numberPad)
            }

            Section("Work") {
                TextField("What needs to be done?", text: $workDescription, axis: .vertical)
                    .font(.title3)
                    .lineLimit(2...5)
            }

            if isEditing {
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(AppointmentStatus.allCases, id: \.self) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .font(.title3)
                    .lineLimit(2...5)
            }

            if isEditing {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Appointment")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Appointment" : "New Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .font(.body.weight(.semibold))
                    .disabled(customerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .confirmationDialog(
            "Delete this appointment? This can't be undone.",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteAndDismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = Double(minutes) / 60
        return hours == floor(hours) ? "\(Int(hours)) hr" : String(format: "%.1f hr", hours)
    }

    private func save() {
        let vehicleYear = Int(vehicleYearText)

        switch mode {
        case .add:
            let appointment = Appointment(
                date: date,
                estimatedDurationMinutes: durationMinutes,
                customerName: customerName.trimmingCharacters(in: .whitespaces),
                customerPhone: customerPhone.trimmingCharacters(in: .whitespaces),
                vehicleMake: vehicleMake.trimmingCharacters(in: .whitespaces),
                vehicleModel: vehicleModel.trimmingCharacters(in: .whitespaces),
                vehicleYear: vehicleYear,
                workDescription: workDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                status: .scheduled,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            context.insert(appointment)
            NotificationScheduler.shared.reschedule(for: appointment, context: context)

        case .edit(let appointment):
            let previousDate = appointment.date
            appointment.date = date
            appointment.estimatedDurationMinutes = durationMinutes
            appointment.customerName = customerName.trimmingCharacters(in: .whitespaces)
            appointment.customerPhone = customerPhone.trimmingCharacters(in: .whitespaces)
            appointment.vehicleMake = vehicleMake.trimmingCharacters(in: .whitespaces)
            appointment.vehicleModel = vehicleModel.trimmingCharacters(in: .whitespaces)
            appointment.vehicleYear = vehicleYear
            appointment.workDescription = workDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            appointment.status = status
            appointment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            appointment.updatedAt = Date()
            NotificationScheduler.shared.reschedule(for: appointment, previousDate: previousDate, context: context)
        }

        dismiss()
    }

    private func deleteAndDismiss() {
        if case .edit(let appointment) = mode {
            let date = appointment.date
            context.delete(appointment)
            NotificationScheduler.shared.cancelAll(for: appointment, onDate: date, context: context)
        }
        dismiss()
    }
}
