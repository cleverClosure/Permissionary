//
//  NotificationsPermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The notifications capability.
public struct NotificationsPermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> NotificationsStatus

    /// Requests notification authorization with the given options.
    ///
    /// The native request always runs and the final state is re-read
    /// afterward: from not determined it may prompt (or grant quietly
    /// when ``NotificationOptions/provisional`` is included), and from a
    /// provisional grant it may prompt to upgrade. The system never
    /// re-prompts after an explicit decision. Denial is returned as a
    /// status. Notifications require no usage-description key.
    public var request: @Sendable (NotificationOptions) async throws -> NotificationsStatus

    /// Returns a stream of status snapshots for observation.
    ///
    /// The stream emits whenever a status read or a completed request
    /// produces a fresh snapshot. It never prompts.
    public var updates: @Sendable () async -> AsyncStream<NotificationsStatus>

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests authorization with options.
    ///   - updates: Returns a stream of status snapshots.
    public init(
        status: @escaping @Sendable () async -> NotificationsStatus,
        request: @escaping @Sendable (NotificationOptions) async throws -> NotificationsStatus,
        updates: @escaping @Sendable () async -> AsyncStream<NotificationsStatus>
    ) {
        self.status = status
        self.request = request
        self.updates = updates
    }

    /// Requests notification authorization with the standard options:
    /// alerts, sounds, and badging.
    public func request() async throws -> NotificationsStatus {
        try await request(.standard)
    }
}
