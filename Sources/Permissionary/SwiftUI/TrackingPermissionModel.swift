//
//  TrackingPermissionModel.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Observation

/// Observable status for the app-tracking-transparency capability.
///
/// The model reads the initial status when created, follows the
/// capability's update stream, and exposes explicit refresh and request
/// operations. Creating or observing it never presents a prompt.
@MainActor
@Observable
public final class TrackingPermissionModel {
    /// The latest known status, nil until the first read completes.
    public private(set) var status: TrackingStatus?

    @ObservationIgnored private let permission: TrackingPermission
    @ObservationIgnored private var observation: Task<Void, Never>?

    /// Creates a model observing the given capability.
    ///
    /// - Parameter permission: The capability to observe.
    public init(permission: TrackingPermission) {
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

    /// Requests authorization and publishes the resulting status.
    ///
    /// Call this while the application is active; the system may report
    /// denial without prompting otherwise.
    @discardableResult
    public func request() async throws -> TrackingStatus {
        let result = try await permission.request()
        status = result
        return result
    }
}
