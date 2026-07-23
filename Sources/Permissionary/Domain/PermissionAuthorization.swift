//
//  PermissionAuthorization.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// A normalized authorization state shared by every permission.
///
/// Cases describe the access the system currently reports, not how that
/// state came to be. Several native paths can produce the same normalized
/// case. Framework-specific semantics are preserved in each capability's
/// typed status, and available follow-up actions are described by
/// `PermissionRecovery`, not by this state.
public enum PermissionAuthorization: Sendable, Equatable {
    /// No authorization decision has been recorded yet. A request may
    /// present a system prompt.
    case notDetermined

    /// Full access is currently available. This includes grants made
    /// without an explicit user decision, such as ephemeral notification
    /// authorization or a provisional Always location grant.
    case authorized

    /// Partial access is currently available, such as a limited photo or
    /// contact selection, provisional notification delivery, or
    /// when-in-use access evaluated against the Always location capability.
    case limited

    /// Access is not available and the system will not prompt. This
    /// includes an explicit denial by the user as well as system-level
    /// switches, such as Location Services being disabled.
    case denied

    /// Access is blocked by a policy outside the user's control, such as
    /// parental controls or device management.
    case restricted

    /// The capability's API cannot be used in the current environment.
    /// This does not describe hardware presence.
    case unavailable
}
