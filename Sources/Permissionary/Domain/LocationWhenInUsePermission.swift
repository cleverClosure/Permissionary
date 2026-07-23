//
//  LocationWhenInUsePermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The when-in-use location capability.
public struct LocationWhenInUsePermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> LocationWhenInUseStatus

    /// Requests when-in-use location access.
    ///
    /// A system prompt appears only from the not-determined state;
    /// otherwise the current status is returned unchanged. Denial and
    /// restriction are returned as statuses. If the caller's task is
    /// cancelled while the prompt is up, the call stops waiting and
    /// returns the current status; the prompt itself is not dismissed.
    /// Throws ``PermissionError/missingUsageDescription(key:)`` when a
    /// prompt would be needed but `NSLocationWhenInUseUsageDescription`
    /// is missing.
    public var request: @Sendable () async throws -> LocationWhenInUseStatus

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    public init(
        status: @escaping @Sendable () async -> LocationWhenInUseStatus,
        request: @escaping @Sendable () async throws -> LocationWhenInUseStatus
    ) {
        self.status = status
        self.request = request
    }
}
