//
//  PermissionStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The minimal surface shared by every capability's typed status.
///
/// Generic interfaces, such as a reusable permission screen, can render
/// normalized authorization and offer recovery without knowing the
/// concrete capability. Capability-specific detail stays on the concrete
/// status types; there is no generic status container.
public protocol PermissionStatus: Sendable {
    /// The normalized authorization state.
    var authorization: PermissionAuthorization { get }

    /// The follow-up action available to the application, if any.
    var recovery: PermissionRecovery? { get }
}
