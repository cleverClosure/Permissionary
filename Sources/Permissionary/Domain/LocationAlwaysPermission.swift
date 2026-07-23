//
//  LocationAlwaysPermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The always location capability.
public struct LocationAlwaysPermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> LocationAlwaysStatus

    /// Requests always location access.
    ///
    /// From the not-determined state this presents the system prompt
    /// and waits for the user's answer; the reported grant can be
    /// provisional. From a when-in-use grant this fires the system's
    /// one-time upgrade request and returns the current status
    /// immediately, because the system does not reveal whether it will
    /// prompt again — observe later status reads for the outcome. All
    /// other states return the current status unchanged. Throws
    /// ``PermissionError/missingUsageDescription(key:)`` when a prompt
    /// would be needed but `NSLocationWhenInUseUsageDescription` or
    /// `NSLocationAlwaysAndWhenInUseUsageDescription` is missing.
    public var request: @Sendable () async throws -> LocationAlwaysStatus

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    public init(
        status: @escaping @Sendable () async -> LocationAlwaysStatus,
        request: @escaping @Sendable () async throws -> LocationAlwaysStatus
    ) {
        self.status = status
        self.request = request
    }
}
