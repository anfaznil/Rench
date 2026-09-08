import SwiftUI
import UserNotifications
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.modelContext) private var context

    @State private var reminderTime: Date = Date()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let priorReminderOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        Form {
            Section("Your Info") {
                TextField("Your Name", text: $settings.userName)
                    .font(.title3)
                TextField("Business Name", text: $settings.businessName)
                    .font(.title3)
            }
            .onChange(of: settings.userName) { _, _ in settings.persist() }
            .onChange(of: settings.businessName) { _, _ in settings.persist() }

            Section {
                DatePicker("Night-Before Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .font(.title3)

                Picker("Reminder Before Appointment", selection: $settings.priorReminderMinutes) {
                    ForEach(priorReminderOptions, id: \.self) { minutes in
                        Text(NotificationContentBuilder.naturalDuration(minutes: minutes)).tag(minutes)
                    }
                }
                .font(.title3)
            } header: {
                Text("Reminders")
            } footer: {
                Text("Rench sends a summary the evening before your appointments at the time above, and a second reminder before each appointment starts — pick how far ahead.")
            }
            .onChange(of: reminderTime) { _, newValue in
                settings.reminderTimeAsDate = newValue
                let changed = settings.persist()
                if changed {
                    NotificationScheduler.shared.rescheduleAll(context: context)
                }
            }
            .onChange(of: settings.priorReminderMinutes) { _, _ in
                let changed = settings.persist()
                if changed {
                    NotificationScheduler.shared.rescheduleAll(context: context)
                }
            }

            Section {
                HStack {
                    Text("Notification Permission")
                    Spacer()
                    Text(notificationStatusLabel)
                        .foregroundStyle(.secondary)
                }
                if notificationStatus != .authorized {
                    Button("Open Notification Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            Section {
                NavigationLink("Siri & Shortcuts") {
                    ShortcutsInfoView()
                }
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            reminderTime = settings.reminderTimeAsDate
            notificationStatus = await NotificationScheduler.shared.currentAuthorizationStatus()
        }
        .onAppear {
            reminderTime = settings.reminderTimeAsDate
        }
    }

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized: return "On"
        case .denied: return "Off"
        case .notDetermined: return "Not Set"
        case .provisional: return "Quiet"
        case .ephemeral: return "Temporary"
        @unknown default: return "Unknown"
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
