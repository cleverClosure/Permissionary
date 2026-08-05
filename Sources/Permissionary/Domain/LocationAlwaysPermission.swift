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

    /// Returns a stream of status snapshots for observation.
    ///
    /// The stream emits whenever a status read, a completed request, or
    /// a system authorization change produces a fresh snapshot; a
    /// provisional Always downgrade arrives here without any
    /// application action. It never prompts.
    public var updates: @Sendable () async -> AsyncStream<LocationAlwaysStatus>

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    ///   - updates: Returns a stream of status snapshots.
    public init(
        status: @escaping @Sendable () async -> LocationAlwaysStatus,
        request: @escaping @Sendable () async throws -> LocationAlwaysStatus,
        updates: @escaping @Sendable () async -> AsyncStream<LocationAlwaysStatus>
    ) {
        self.status = status
        self.request = request
        self.updates = updates
    }
}
