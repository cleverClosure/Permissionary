//
//  StatusHub.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Foundation

actor StatusHub<Status: Sendable> {
    private var subscribers: [UUID: AsyncStream<Status>.Continuation] = [:]

    func publish(_ status: Status) {
        for continuation in subscribers.values {
            continuation.yield(status)
        }
    }

    func stream() -> AsyncStream<Status> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            subscribers[id] = continuation
            continuation.onTermination = { _ in
                Task { await self.remove(id) }
            }
        }
    }

    private func remove(_ id: UUID) {
        subscribers[id] = nil
    }
}
