import SwiftUI
import UIKit

/// One-time explainer for Settings > Accessibility > Spoken Content > "Speak Notifications".
///
/// iOS has no public API to deep-link directly into that specific Accessibility pane — only
/// `UIApplication.openSettingsURLString`, which opens Rench's own Settings page, is available
/// without using private URL schemes (which would risk App Store rejection). So this screen
/// opens the app's Settings page and spells out the exact path to tap next.
struct SpokenContentPromptView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "speaker.wave.2.bubble.left.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)

            Text("Hear Your Reminders")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Turn on Speak Notifications and iOS will read your appointment reminders out loud automatically — handy when your hands are full or dirty.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 10) {
                Text("In Settings, tap:")
                    .font(.headline)
                Text("Accessibility → Spoken Content → Speak Notifications")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                onDismiss()
            } label: {
                Text("Open Settings")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button("Maybe Later") {
                onDismiss()
            }
            .font(.body)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled(false)
    }
}
