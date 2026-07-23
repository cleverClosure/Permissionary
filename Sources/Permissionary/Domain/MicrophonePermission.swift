//
//  MicrophonePermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The microphone capability.
public struct MicrophonePermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> MicrophoneStatus

    /// Requests microphone access.
    ///
    /// A system prompt appears only from the not-determined state;
    /// otherwise the current status is returned unchanged. Denial is
    /// returned as a status. Throws
    /// ``PermissionError/missingUsageDescription(key:)`` when a prompt
    /// would be needed but `NSMicrophoneUsageDescription` is missing.
    public var request: @Sendable () async throws -> MicrophoneStatus

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    public init(
        status: @escaping @Sendable () async -> MicrophoneStatus,
        request: @escaping @Sendable () async throws -> MicrophoneStatus
    ) {
        self.status = status
        self.request = request
    }
}
