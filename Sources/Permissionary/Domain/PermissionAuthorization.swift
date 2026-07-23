//
//  PermissionAuthorization.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// A normalized authorization state shared by every permission.
///
/// This is the small, capability-independent layer intended for generic
/// application UI. Framework-specific semantics are preserved in each
/// capability's typed status; see the permission matrix for the mapping
/// from native states.
public enum PermissionAuthorization: Sendable, Equatable {
    /// The user has not been asked yet. A request may present a system prompt.
    case notDetermined

    /// The user granted full access.
    case authorized

    /// A partial grant that permits reduced functionality, such as a limited
    /// photo or contact selection, provisional notification delivery, or
    /// when-in-use access viewed from the Always location capability.
    case limited

    /// The user declined access. The system will not prompt again; recovery
    /// goes through Settings.
    case denied

    /// Access is blocked by a policy the user may not control, such as
    /// parental controls or device management. Settings may not resolve it.
    case restricted

    /// The capability's API cannot be used in the current environment.
    /// This does not describe hardware presence.
    case unavailable
}
