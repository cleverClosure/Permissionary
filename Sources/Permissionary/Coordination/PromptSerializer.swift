//
//  PromptSerializer.swift
//  Permissionary
//
//  Created by Tim Isaev
//

actor PromptSerializer {
    private var isBusy = false
    private var queue: [CheckedContinuation<Void, Never>] = []

    func run<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async rethrows -> Value {
        await acquire()
        do {
            let value = try await operation()
            release()
            return value
        } catch {
            release()
            throw error
        }
    }

    private func acquire() async {
        guard isBusy else {
            isBusy = true
            return
        }
        await withCheckedContinuation { queue.append($0) }
    }

    private func release() {
        guard queue.isEmpty else {
            queue.removeFirst().resume()
            return
        }
        isBusy = false
    }
}

struct RequestCoordination: Sendable {
    let serializer = PromptSerializer()

    init() {}
}
