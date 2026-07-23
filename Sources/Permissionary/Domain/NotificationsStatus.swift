//
//  NotificationsStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The notifications capability's typed status.
///
/// ``PermissionAuthorization/limited`` means a provisional grant:
/// notifications are delivered quietly and the user has not decided yet.
/// ``grant`` preserves the exact native grant behind the normalized
/// state, and ``settings`` carries the detailed delivery channels.
public struct NotificationsStatus: PermissionStatus, Equatable {
    /// The normalized authorization state.
    public let authorization: PermissionAuthorization

    /// The exact grant behind the normalized state, if any.
    public let grant: NotificationGrant?

    /// The user's detailed notification settings.
    public let settings: NotificationSettings

    /// The follow-up action available to the application, if any.
    public let recovery: PermissionRecovery?

    /// Creates a status, typically for tests or previews.
    ///
    /// - Parameters:
    ///   - authorization: The normalized authorization state.
    ///   - grant: The exact grant behind the normalized state.
    ///   - settings: The detailed notification settings.
    ///   - recovery: The follow-up action available to the application.
    public init(
        authorization: PermissionAuthorization,
        grant: NotificationGrant?,
        settings: NotificationSettings,
        recovery: PermissionRecovery?
    ) {
        self.authorization = authorization
        self.grant = grant
        self.settings = settings
        self.recovery = recovery
    }
}
