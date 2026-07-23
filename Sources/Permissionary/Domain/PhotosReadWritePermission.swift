//
//  PhotosReadWritePermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The photo library read/write capability.
public struct PhotosReadWritePermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> PhotosReadWriteStatus

    /// Requests read/write photo library access.
    ///
    /// A system prompt appears only from the not-determined state;
    /// otherwise the current status is returned unchanged. Denial,
    /// restriction, and a limited selection are returned as statuses.
    /// Throws ``PermissionError/missingUsageDescription(key:)`` when a
    /// prompt would be needed but `NSPhotoLibraryUsageDescription` is
    /// missing.
    public var request: @Sendable () async throws -> PhotosReadWriteStatus

    /// Returns a stream of status snapshots for observation.
    ///
    /// The stream emits whenever a status read or a completed request
    /// produces a fresh snapshot. It never prompts.
    public var updates: @Sendable () async -> AsyncStream<PhotosReadWriteStatus>

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    ///   - updates: Returns a stream of status snapshots.
    public init(
        status: @escaping @Sendable () async -> PhotosReadWriteStatus,
        request: @escaping @Sendable () async throws -> PhotosReadWriteStatus,
        updates: @escaping @Sendable () async -> AsyncStream<PhotosReadWriteStatus>
    ) {
        self.status = status
        self.request = request
        self.updates = updates
    }
}
