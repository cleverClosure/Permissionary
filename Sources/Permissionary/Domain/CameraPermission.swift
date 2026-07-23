//
//  CameraPermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The camera capability.
public struct CameraPermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> CameraStatus

    /// Requests camera access.
    ///
    /// A system prompt appears only from the not-determined state;
    /// otherwise the current status is returned unchanged. Denial and
    /// restriction are returned as statuses. Throws
    /// ``PermissionError/missingUsageDescription(key:)`` when a prompt
    /// would be needed but `NSCameraUsageDescription` is missing.
    public var request: @Sendable () async throws -> CameraStatus

    /// Returns a stream of status snapshots for observation.
    ///
    /// The stream emits whenever a status read or a completed request
    /// produces a fresh snapshot. It never prompts.
    public var updates: @Sendable () async -> AsyncStream<CameraStatus>

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    ///   - updates: Returns a stream of status snapshots.
    public init(
        status: @escaping @Sendable () async -> CameraStatus,
        request: @escaping @Sendable () async throws -> CameraStatus,
        updates: @escaping @Sendable () async -> AsyncStream<CameraStatus>
    ) {
        self.status = status
        self.request = request
        self.updates = updates
    }
}
