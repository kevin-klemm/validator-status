import Foundation

/// Persists last-known validator health in shared UserDefaults
/// so the widget can detect state transitions between refreshes.
final class ValidatorStateStore {

    static let shared = ValidatorStateStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: "group.com.validatorstatus.shared")
            ?? .standard
    }

    // MARK: - State tracking

    /// Persist the latest health state. Returns `true` when the state changed
    /// compared to the previous recorded value (triggers a notification).
    @discardableResult
    func recordState(index: Int, isHealthy: Bool) -> Bool {
        let prevIndex = defaults.object(forKey: "lastIndex") as? Int
        let prevHealthy = defaults.object(forKey: "lastHealthy") as? Bool

        defaults.set(index, forKey: "lastIndex")
        defaults.set(isHealthy, forKey: "lastHealthy")

        // First observation is never treated as a change.
        guard prevHealthy != nil else { return false }
        return prevIndex != index || prevHealthy != isHealthy
    }

    var lastHealthy: Bool? {
        defaults.object(forKey: "lastHealthy") as? Bool
    }

    var lastIndex: Int? {
        defaults.object(forKey: "lastIndex") as? Int
    }

    func reset() {
        defaults.removeObject(forKey: "lastIndex")
        defaults.removeObject(forKey: "lastHealthy")
    }
}
