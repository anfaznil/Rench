import SwiftUI

/// Explains the built-in Siri phrases and how to customize them via the Shortcuts app.
struct ShortcutsInfoView: View {
    private let examples = [
        "Ask Rench what's on my schedule",
        "Ask Rench what's my next appointment",
        "Ask Rench what's on my schedule tomorrow"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                    Text("Ask Rench Out Loud")
                        .font(.title2.bold())
                    Text("You can ask Siri about your schedule hands-free. Try saying:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(examples, id: \.self) { phrase in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "quote.opening")
                                .foregroundStyle(.secondary)
                            Text(phrase)
                                .font(.title3.weight(.medium))
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Prefer to say it differently?")
                        .font(.headline)
                    Text("Open the Shortcuts app, find Rench's shortcuts under the My Shortcuts tab, and record your own phrase for each one.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Siri & Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
