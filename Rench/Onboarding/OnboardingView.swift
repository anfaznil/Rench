import SwiftUI

/// First-launch setup: name/business name + reminder time, then a notification permission ask.
struct OnboardingView: View {
    @EnvironmentObject private var settings: SettingsViewModel

    @State private var step = 0
    @State private var name = ""
    @State private var businessName = ""
    @State private var reminderTime = Self.defaultReminderTime()

    private static func defaultReminderTime() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 19
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    var body: some View {
        VStack {
            switch step {
            case 0:
                welcomeStep
            default:
                notificationStep
            }
        }
        .animation(.default, value: step)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Rench")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Let's set up your schedule.")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name")
                        .font(.headline)
                    TextField("e.g. Mike", text: $name)
                        .font(.title3)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Business Name (Optional)")
                        .font(.headline)
                    TextField("e.g. Mike's Mobile Mechanic", text: $businessName)
                        .font(.title3)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Night-Before Reminder Time")
                        .font(.headline)
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                step = 1
            } label: {
                Text("Continue")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty && businessName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var notificationStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Stay On Schedule")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Rench sends you a reminder the night before each appointment, and again an hour before it starts.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                Task {
                    await NotificationScheduler.shared.requestAuthorizationIfNeeded()
                    finish()
                }
            } label: {
                Text("Enable Reminders")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button("Not Now") {
                finish()
            }
            .font(.body)
            .padding(.bottom, 24)
        }
    }

    private func finish() {
        settings.completeOnboarding(name: name, businessName: businessName, reminderTime: reminderTime)
    }
}
