//
//  NotificationSettings.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// A value copy of the user's detailed notification settings.
///
/// The native settings object is not Sendable and is never exposed;
/// this snapshot carries the same information as plain values. Settings
/// can change in the Settings app at any time without terminating the
/// application, so re-read status when the application becomes active.
public struct NotificationSettings: Sendable, Equatable {
    /// Whether alerts may be displayed.
    public let alert: NotificationSetting

    /// Whether sounds may be played.
    public let sound: NotificationSetting

    /// Whether the application badge may be updated.
    public let badge: NotificationSetting

    /// Whether notifications appear on the lock screen.
    public let lockScreen: NotificationSetting

    /// Whether notifications appear in Notification Center.
    public let notificationCenter: NotificationSetting

    /// Whether critical alerts may ignore the mute switch.
    public let criticalAlert: NotificationSetting

    /// Whether time-sensitive notifications may break through focus.
    public let timeSensitive: NotificationSetting

    /// The presentation style for alerts.
    public let alertStyle: NotificationAlertStyle

    /// Creates a settings snapshot, typically for tests or previews.
    ///
    /// - Parameters:
    ///   - alert: Whether alerts may be displayed.
    ///   - sound: Whether sounds may be played.
    ///   - badge: Whether the application badge may be updated.
    ///   - lockScreen: Whether notifications appear on the lock screen.
    ///   - notificationCenter: Whether notifications appear in
    ///     Notification Center.
    ///   - criticalAlert: Whether critical alerts may ignore the mute
    ///     switch.
    ///   - timeSensitive: Whether time-sensitive notifications may break
    ///     through focus.
    ///   - alertStyle: The presentation style for alerts.
    public init(
        alert: NotificationSetting,
        sound: NotificationSetting,
        badge: NotificationSetting,
        lockScreen: NotificationSetting,
        notificationCenter: NotificationSetting,
        criticalAlert: NotificationSetting,
        timeSensitive: NotificationSetting,
        alertStyle: NotificationAlertStyle
    ) {
        self.alert = alert
        self.sound = sound
        self.badge = badge
        self.lockScreen = lockScreen
        self.notificationCenter = notificationCenter
        self.criticalAlert = criticalAlert
        self.timeSensitive = timeSensitive
        self.alertStyle = alertStyle
    }

    /// A snapshot with every channel disabled, useful as a fixture for
    /// denied or undetermined states.
    public static let allDisabled = NotificationSettings(
        alert: .disabled,
        sound: .disabled,
        badge: .disabled,
        lockScreen: .disabled,
        notificationCenter: .disabled,
        criticalAlert: .notSupported,
        timeSensitive: .notSupported,
        alertStyle: .none
    )
}
