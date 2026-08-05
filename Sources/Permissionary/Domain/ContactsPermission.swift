//
//  ContactsPermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The contacts capability.
public struct ContactsPermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> ContactsStatus

    /// Requests contacts access.
    ///
    /// A system prompt appears only from the not-determined state;
    /// otherwise the current status is returned unchanged. Denial,
    /// restriction, and a limited selection are returned as statuses,
    /// even though the native API reports denial as an error. Throws
    /// ``PermissionError/missingUsageDescription(key:)`` when a prompt
    /// would be needed but `NSContactsUsageDescription` is missing.
    public var request: @Sendable () async throws -> ContactsStatus

    /// Returns a stream of status snapshots for observation.
    ///
    /// The stream emits whenever a status read or a completed request
    /// produces a fresh snapshot. It never prompts.
    public var updates: @Sendable () async -> AsyncStream<ContactsStatus>

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    ///   - updates: Returns a stream of status snapshots.
    public init(
        status: @escaping @Sendable () async -> ContactsStatus,
        request: @escaping @Sendable () async throws -> ContactsStatus,
        updates: @escaping @Sendable () async -> AsyncStream<ContactsStatus>
    ) {
        self.status = status
        self.request = request
        self.updates = updates
    }
}
