import SwiftUI

/// Top-level switch between the first-launch onboarding flow and the main app.
struct RootContainerView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var showSpokenContentPrompt = false

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                RootTabView()
                    .sheet(isPresented: $showSpokenContentPrompt) {
                        SpokenContentPromptView {
                            settings.markSpokenContentPromptSeen()
                            showSpokenContentPrompt = false
                        }
                    }
                    .onAppear {
                        if !settings.hasSeenSpokenContentPrompt {
                            showSpokenContentPrompt = true
                        }
                    }
            } else {
                OnboardingView()
            }
        }
    }
}
