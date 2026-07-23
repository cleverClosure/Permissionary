//
//  ContactsPermissionModel.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Observation

/// Observable status for the contacts capability.
///
/// The model reads the initial status when created, follows the
/// capability's update stream, and exposes explicit refresh and request
/// operations. Creating or observing it never presents a prompt.
@MainActor
@Observable
public final class ContactsPermissionModel {
    /// The latest known status, nil until the first read completes.
    public private(set) var status: ContactsStatus?

    @ObservationIgnored private let permission: ContactsPermission
    @ObservationIgnored private var observation: Task<Void, Never>?

    /// Creates a model observing the given capability.
    ///
    /// - Parameter permission: The capability to observe.
    public init(permission: ContactsPermission) {
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
    public func request() async throws -> ContactsStatus {
        let result = try await permission.request()
        status = result
        return result
    }
}
