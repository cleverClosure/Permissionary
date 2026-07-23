//
//  PhotosAddOnlyPermission.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The photo library add-only capability.
public struct PhotosAddOnlyPermission: Sendable {
    /// Reads the current status without presenting a system prompt.
    public var status: @Sendable () async -> PhotosAddOnlyStatus

    /// Requests add-only photo library access.
    ///
    /// A system prompt appears only from the not-determined state;
    /// otherwise the current status is returned unchanged. Denial and
    /// restriction are returned as statuses. Throws
    /// ``PermissionError/missingUsageDescription(key:)`` when a prompt
    /// would be needed but `NSPhotoLibraryAddUsageDescription` is missing.
    public var request: @Sendable () async throws -> PhotosAddOnlyStatus

    /// Creates a capability from its operations.
    ///
    /// - Parameters:
    ///   - status: Reads the current status.
    ///   - request: Requests access.
    public init(
        status: @escaping @Sendable () async -> PhotosAddOnlyStatus,
        request: @escaping @Sendable () async throws -> PhotosAddOnlyStatus
    ) {
        self.status = status
        self.request = request
    }
}
