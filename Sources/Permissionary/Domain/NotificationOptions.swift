//
//  NotificationOptions.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The delivery capabilities requested alongside notification
/// authorization.
///
/// Options are part of the permission semantics: what the user is asked
/// for depends on them, so they are a per-request parameter rather than
/// client configuration. ``standard`` covers the common case.
public struct NotificationOptions: OptionSet, Sendable {
    /// The raw bit mask of the combined options.
    public let rawValue: Int

    /// Creates options from a raw bit mask.
    ///
    /// - Parameter rawValue: The raw bit mask.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Display alerts.
    public static let alert = NotificationOptions(rawValue: 1 << 0)

    /// Play sounds.
    public static let sound = NotificationOptions(rawValue: 1 << 1)

    /// Update the application badge.
    public static let badge = NotificationOptions(rawValue: 1 << 2)

    /// Deliver quietly on a trial basis without a prompt; the system
    /// reports the result as a provisional grant.
    public static let provisional = NotificationOptions(rawValue: 1 << 3)

    /// Play critical sounds that ignore the mute switch; requires a
    /// special entitlement.
    public static let criticalAlert = NotificationOptions(rawValue: 1 << 4)

    /// Display notifications in CarPlay.
    public static let carPlay = NotificationOptions(rawValue: 1 << 5)

    /// Tell the system the application offers its own notification
    /// settings screen.
    public static let providesAppNotificationSettings = NotificationOptions(rawValue: 1 << 6)

    /// The default request: alerts, sounds, and badging.
    public static let standard: NotificationOptions = [.alert, .sound, .badge]
}
