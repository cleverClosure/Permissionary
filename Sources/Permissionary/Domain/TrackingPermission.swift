//
//  TrackingPermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The app-tracking-transparency capability.
public struct TrackingPermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> TrackingStatus

    /// Requests tracking authorization.
    ///
    /// Call this while the application is active; the system may report
    /// denial without prompting otherwise. A system prompt appears only
    /// from the not-determined state; otherwise the current status is
    /// returned unchanged. Denial and restriction are returned as
    /// statuses. Throws
    /// ``PermissionError/missingUsageDescription(key:)`` when a prompt
    /// would be needed but `NSUserTrackingUsageDescription` is missing.
    public var request: @Sendable () async throws -> TrackingStatus

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    public init(
        status: @escaping @Sendable () async -> TrackingStatus,
        request: @escaping @Sendable () async throws -> TrackingStatus
    ) {
        self.status = status
        self.request = request
    }
}
