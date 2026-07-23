//
//  PermissionsClient.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The injectable entry point for reading and requesting permissions.
///
/// Every operation is exposed as a replaceable value, so tests and
/// previews construct a client from deterministic pieces without a global
/// singleton. Use ``live`` for the client backed by the real system
/// frameworks. Capability accessors are added as their adapters are
/// implemented.
public struct PermissionsClient: Sendable {
    /// Opens the application's page in the Settings app.
    ///
    /// Call this only from an explicit user action, typically after a
    /// status reports ``PermissionRecovery/openSettings``. The library
    /// never opens Settings automatically.
    public var openSettings: @Sendable () async -> Void

    /// Creates a client from its operations.
    ///
    /// - Parameter openSettings: Opens the application's page in Settings.
    public init(openSettings: @escaping @Sendable () async -> Void) {
        self.openSettings = openSettings
    }
}
