import Foundation

/// Identifiers shared by the app and widget extension targets. Both targets' entitlements
/// must reference the same App Group and iCloud container for the shared SwiftData store
/// and CloudKit sync to work.
enum AppGroup {
    static let identifier = "group.com.rench.app"
    static let iCloudContainerIdentifier = "iCloud.com.rench.app"

    /// `nil` here means the App Group entitlement isn't actually provisioned for this build —
    /// most commonly because Signing & Capabilities → App Groups wasn't added/checked for one
    /// of the two targets, or a fresh device install hasn't picked up a signing change yet. When
    /// this is `nil`, the app and widget each silently fall back to their own separate, private
    /// storage — they'll never see each other's data, which shows up as "the widget never
    /// updates" even though the app itself works fine.
    static var containerURL: URL? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        #if DEBUG
        if url == nil {
            print("Rench: App Group '\(identifier)' container is unavailable — check that App Groups is added in Signing & Capabilities for BOTH the Rench and RenchWidgetExtension targets, with '\(identifier)' checked.")
        }
        #endif
        return url
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
