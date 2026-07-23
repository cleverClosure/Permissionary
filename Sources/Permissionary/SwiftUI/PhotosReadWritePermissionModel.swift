//
//  PhotosReadWritePermissionModel.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Observation

/// Observable status for the photo library read/write capability.
///
/// The model reads the initial status when created, follows the
/// capability's update stream, and exposes explicit refresh and request
/// operations. Creating or observing it never presents a prompt.
@MainActor
@Observable
public final class PhotosReadWritePermissionModel {
    /// The latest known status, nil until the first read completes.
    public private(set) var status: PhotosReadWriteStatus?

    @ObservationIgnored private let permission: PhotosReadWritePermission
    @ObservationIgnored private var observation: Task<Void, Never>?

    /// Creates a model observing the given capability.
    ///
    /// - Parameter permission: The capability to observe.
    public init(permission: PhotosReadWritePermission) {
        self.permission = permission
        observation = Task { [weak self, permission] in
            let initial = await permission.status()
            self?.status = initial
            let updates = await permission.updates()
            for await update in updates {
                guard let self else { break }
                self.status = update
            }
        }
    }

    deinit {
        observation?.cancel()
    }

    /// Re-reads the current status.
    public func refresh() async {
        status = await permission.status()
    }

    /// Requests access and publishes the resulting status.
    @discardableResult
    public func request() async throws -> PhotosReadWriteStatus {
        let result = try await permission.request()
        status = result
        return result
    }
}
