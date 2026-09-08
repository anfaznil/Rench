import SwiftUI
import SwiftData

@main
struct RenchApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var settings = SettingsViewModel()

    init() {
        modelContainer = PersistenceController.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(settings)
                .task {
                    NotificationScheduler.shared.rescheduleAll(context: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
