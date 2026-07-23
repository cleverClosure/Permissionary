//
//  LocationScript.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import CoreLocation
import Synchronization

@testable import Permissionary

final class LocationScript: Sendable {
    private let states: Mutex<[CLAuthorizationStatus]>
    private let accuracy: Mutex<CLAccuracyAuthorization>
    private let whenInUseFires = Mutex(0)
    private let alwaysFires = Mutex(0)
    private let changeContinuations = Mutex<[AsyncStream<Void>.Continuation]>([])
    private let emitsChangeOnFire: Bool

    init(
        states: [CLAuthorizationStatus],
        accuracy: CLAccuracyAuthorization = .fullAccuracy,
        emitsChangeOnFire: Bool = true
    ) {
        self.states = Mutex(states)
        self.accuracy = Mutex(accuracy)
        self.emitsChangeOnFire = emitsChangeOnFire
    }

    var whenInUseFireCount: Int {
        whenInUseFires.withLock { $0 }
    }

    var alwaysFireCount: Int {
        alwaysFires.withLock { $0 }
    }

    func shim() -> LocationShim {
        LocationShim(
            authorizationStatus: { self.nextState() },
            accuracyAuthorization: { self.accuracy.withLock { $0 } },
            requestWhenInUseAuthorization: {
                self.whenInUseFires.withLock { $0 += 1 }
                self.emitChangeIfConfigured()
            },
            requestAlwaysAuthorization: {
                self.alwaysFires.withLock { $0 += 1 }
                self.emitChangeIfConfigured()
            },
            authorizationChanges: {
                let (stream, continuation) = AsyncStream<Void>.makeStream()
                self.changeContinuations.withLock { $0.append(continuation) }
                return stream
            }
        )
    }

    private func nextState() -> CLAuthorizationStatus {
        states.withLock { remaining in
            remaining.count > 1 ? remaining.removeFirst() : remaining[0]
        }
    }

    private func emitChangeIfConfigured() {
        guard emitsChangeOnFire else { return }
        changeContinuations.withLock { continuations in
            for continuation in continuations {
                continuation.yield()
            }
        }
    }
}
