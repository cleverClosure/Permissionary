//
//  NotificationsPermissionModel.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Observation

/// Observable status for the notifications capability.
///
/// The model reads the initial status when created, follows the
/// capability's update stream, and exposes explicit refresh and request
/// operations. Creating or observing it never presents a prompt.
@MainActor
@Observable
public final class NotificationsPermissionModel {
    /// The latest known status, nil until the first read completes.
    public private(set) var status: NotificationsStatus?

    @ObservationIgnored private let permission: NotificationsPermission
    @ObservationIgnored private var observation: Task<Void, Never>?

    /// Creates a model observing the given capability.
    ///
    /// - Parameter permission: The capability to observe.
    public init(permission: NotificationsPermission) {
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
    /// - Parameter options: The delivery capabilities to request;
    ///   defaults to ``NotificationOptions/standard``.
    /// - Returns: The status after the request completes.
    /// - Throws: A ``PermissionError`` for exceptional failures; denial
    ///   is returned as a status.
    @discardableResult
    public func request(
        _ options: NotificationOptions = .standard
    ) async throws -> NotificationsStatus {
        let result = try await permission.request(options)
        status = result
        return result
    }
}
