//
//  NotificationAlertStyle.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The presentation style the user chose for notification alerts.
public enum NotificationAlertStyle: Sendable, Equatable {
    /// Alerts are not shown.
    case none

    /// Alerts appear briefly and dismiss themselves.
    case banner

    /// Alerts stay on screen until dismissed.
    case alert
}
