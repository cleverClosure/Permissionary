//
//  RequestCoalescer.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Foundation

actor RequestCoalescer<Status: Sendable> {
    private var waiters: [UUID: CheckedContinuation<Result<Status, any Error>?, Never>] = [:]
    private var isRunning = false

    func run(
        _ operation: @escaping @Sendable () async throws -> Status,
        ifCancelled currentStatus: @escaping @Sendable () async -> Status
    ) async throws -> Status {
        guard !Task.isCancelled else { return await currentStatus() }
        let id = UUID()
        let result = await withTaskCancellationHandler {
            await withCheckedContinuation {
                (continuation: CheckedContinuation<Result<Status, any Error>?, Never>) in
                waiters[id] = continuation
                startRunnerIfNeeded(operation)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
        guard let result else { return await currentStatus() }
        return try result.get()
    }

    private func startRunnerIfNeeded(_ operation: @escaping @Sendable () async throws -> Status) {
        guard !isRunning else { return }
        isRunning = true
        Task {
            let result: Result<Status, any Error>
            do {
                result = .success(try await operation())
            } catch {
                result = .failure(error)
            }
            self.finish(with: result)
        }
    }

    private func finish(with result: Result<Status, any Error>) {
        isRunning = false
        let resumed = waiters
        waiters = [:]
        for continuation in resumed.values {
            continuation.resume(returning: result)
        }
    }

    private func cancelWaiter(_ id: UUID) {
        guard let continuation = waiters.removeValue(forKey: id) else { return }
        continuation.resume(returning: nil)
    }
}
