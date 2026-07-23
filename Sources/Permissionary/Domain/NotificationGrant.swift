//
//  NotificationGrant.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The exact kind of notification grant the system reported.
///
/// Normalization folds provisional into
/// ``PermissionAuthorization/limited`` and ephemeral into
/// ``PermissionAuthorization/authorized``; this value preserves which
/// native grant produced the normalized state.
public enum NotificationGrant: Sendable, Equatable {
    /// The user explicitly authorized notifications.
    case standard

    /// Notifications are delivered quietly on a trial basis; the user
    /// has not made an explicit decision yet.
    case provisional

    /// A temporary grant for an App Clip session.
    case ephemeral
}
