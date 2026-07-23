//
//  LocationAlwaysPermissionModel.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Observation

/// Observable status for the always location capability.
///
/// The model reads the initial status when created, follows the
/// capability's update stream — including system authorization changes
/// delivered through the location delegate, such as a provisional
/// Always downgrade — and exposes explicit refresh and request
/// operations. Creating or observing it never presents a prompt.
@MainActor
@Observable
public final class LocationAlwaysPermissionModel {
    /// The latest known status, nil until the first read completes.
    public private(set) var status: LocationAlwaysStatus?

    @ObservationIgnored private let permission: LocationAlwaysPermission
    @ObservationIgnored private var observation: Task<Void, Never>?

    /// Creates a model observing the given capability.
    ///
    /// - Parameter permission: The capability to observe.
    public init(permission: LocationAlwaysPermission) {
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
    public func request() async throws -> LocationAlwaysStatus {
        let result = try await permission.request()
        status = result
        return result
    }
}
