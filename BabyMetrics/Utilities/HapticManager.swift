import UIKit

/// Centralized haptic feedback per the UX spec.
enum HapticManager {
    /// Medium impact — used when starting/stopping a timer.
    static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Success notification — used when saving an entry.
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}
