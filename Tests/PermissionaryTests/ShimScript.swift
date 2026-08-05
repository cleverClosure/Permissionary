//
//  ShimScript.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Synchronization

final class ShimScript<Native: Sendable>: Sendable {
    private let states: Mutex<[Native]>
    private let prompts = Mutex(0)

    init(_ states: Native...) {
        self.states = Mutex(Array(states))
    }

    init(sequence: [Native]) {
        self.states = Mutex(sequence)
    }

    func nextState() -> Native {
        states.withLock { remaining in
            remaining.count > 1 ? remaining.removeFirst() : remaining[0]
        }
    }

    func recordPrompt() {
        prompts.withLock { $0 += 1 }
    }

    var promptCount: Int {
        prompts.withLock { $0 }
    }
}
