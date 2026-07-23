//
//  PermissionRecovery.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// A follow-up action the application can offer for the current status.
///
/// Statuses describe the available recovery; the application decides
/// whether and when to execute it, always from an explicit user action.
/// The library never performs recovery automatically. A restricted status
/// does not automatically imply Settings recovery, because Settings cannot
/// always lift a policy restriction.
public enum PermissionRecovery: Sendable, Equatable {
    /// Direct the user to the application's page in the Settings app.
    case openSettings

    /// Let the user change a limited selection, such as the accessible
    /// photos or contacts, without leaving the application.
    case manageLimitedSelection
}
