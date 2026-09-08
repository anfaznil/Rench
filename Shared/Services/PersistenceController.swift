import Foundation
import SwiftData

/// Builds the shared SwiftData `ModelContainer` used by the app, the widget extension, and
/// (with in-memory storage) unit tests. The store file lives in the App Group container so
/// the widget can read the same data the app writes.
enum PersistenceController {
    static let schema = Schema([Appointment.self])

    /// Master switch for CloudKit sync. **Leave this `false` until the app has been signed with
    /// a real Apple Developer Team ID and the iCloud/CloudKit capability (with the matching App
    /// Group) has actually been added in Xcode's Signing & Capabilities tab.**
    ///
    /// This can't safely be a runtime auto-detect: when the `com.apple.developer.icloud-services`
    /// entitlement isn't genuinely present, SwiftData's CloudKit mirroring doesn't fail
    /// gracefully — it can crash the process outright from a background queue deep inside Core
    /// Data's `NSCloudKitMirroringDelegate`, *after* `ModelContainer` init has already returned
    /// successfully, so a `try?`/`catch` around container creation cannot intercept it. Until
    /// signing is configured, the app runs perfectly well on local-only SwiftData storage; once
    /// you've added your Team ID and the capability is real, flip this to `true` and rebuild.
    static var cloudKitSyncEnabled = false

    static func makeContainer(cloudKitEnabled: Bool = cloudKitSyncEnabled) -> ModelContainer {
        let storeURL = (AppGroup.containerURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!)
            .appendingPathComponent("Rench.sqlite")
        #if DEBUG
        print("Rench: SwiftData store at \(storeURL.path)")
        #endif

        if cloudKitEnabled {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private(AppGroup.iCloudContainerIdentifier)
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                return container
            }
            #if DEBUG
            print("Rench: CloudKit-backed store unavailable; falling back to local-only storage.")
            #endif
        }

        let localConfig = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return container
        }

        // Last resort so the app never fails to launch outright.
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memoryConfig])
    }
}
