//
//  Location.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import CoreLocation

struct LocationShim: Sendable {
    var authorizationStatus: @Sendable () async -> CLAuthorizationStatus
    var accuracyAuthorization: @Sendable () async -> CLAccuracyAuthorization
    var requestWhenInUseAuthorization: @Sendable () async -> Void
    var requestAlwaysAuthorization: @Sendable () async -> Void
    var authorizationChanges: @Sendable () async -> AsyncStream<Void>

    static let live = LocationShim(
        authorizationStatus: { await LocationManagerBox.shared.currentStatus() },
        accuracyAuthorization: { await LocationManagerBox.shared.currentAccuracy() },
        requestWhenInUseAuthorization: { await LocationManagerBox.shared.requestWhenInUse() },
        requestAlwaysAuthorization: { await LocationManagerBox.shared.requestAlways() },
        authorizationChanges: { await LocationManagerBox.shared.changes() }
    )
}

@MainActor
final class LocationManagerBox: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManagerBox()

    private let manager: CLLocationManager
    private var subscribers: [UUID: AsyncStream<Void>.Continuation] = [:]

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    func currentStatus() -> CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func currentAccuracy() -> CLAccuracyAuthorization {
        manager.accuracyAuthorization
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    func changes() -> AsyncStream<Void> {
        let id = UUID()
        return AsyncStream { continuation in
            subscribers[id] = continuation
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.subscribers[id] = nil
                }
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            for continuation in self.subscribers.values {
                continuation.yield()
            }
        }
    }
}

extension LocationAccuracy {
    init(native: CLAccuracyAuthorization) {
        switch native {
        case .fullAccuracy: self = .full
        case .reducedAccuracy: self = .reduced
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "locationAccuracy")
            self = .reduced
        }
    }
}

extension LocationWhenInUseStatus {
    init(native: CLAuthorizationStatus, nativeAccuracy: CLAccuracyAuthorization) {
        switch native {
        case .notDetermined:
            self.init(authorization: .notDetermined, accuracy: nil, recovery: nil)
        case .authorizedWhenInUse, .authorizedAlways:
            self.init(
                authorization: .authorized,
                accuracy: LocationAccuracy(native: nativeAccuracy),
                recovery: nil
            )
        case .denied:
            self.init(authorization: .denied, accuracy: nil, recovery: .openSettings)
        case .restricted:
            self.init(authorization: .restricted, accuracy: nil, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(
                rawValue: Int(native.rawValue),
                capability: "locationWhenInUse"
            )
            self.init(authorization: .denied, accuracy: nil, recovery: .openSettings)
        }
    }
}

extension LocationAlwaysStatus {
    init(native: CLAuthorizationStatus, nativeAccuracy: CLAccuracyAuthorization) {
        switch native {
        case .notDetermined:
            self.init(authorization: .notDetermined, accuracy: nil, recovery: nil)
        case .authorizedWhenInUse:
            self.init(
                authorization: .limited,
                accuracy: LocationAccuracy(native: nativeAccuracy),
                recovery: nil
            )
        case .authorizedAlways:
            self.init(
                authorization: .authorized,
                accuracy: LocationAccuracy(native: nativeAccuracy),
                recovery: nil
            )
        case .denied:
            self.init(authorization: .denied, accuracy: nil, recovery: .openSettings)
        case .restricted:
            self.init(authorization: .restricted, accuracy: nil, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(rawValue: Int(native.rawValue), capability: "locationAlways")
            self.init(authorization: .denied, accuracy: nil, recovery: .openSettings)
        }
    }
}

enum LocationRequestFlow {
    static let whenInUseKey = "NSLocationWhenInUseUsageDescription"
    static let alwaysKey = "NSLocationAlwaysAndWhenInUseUsageDescription"

    static func validate(keys: [String], infoPlist: InfoPlistReader) throws {
        for key in keys {
            guard let description = infoPlist.string(key), !description.isEmpty else {
                throw PermissionError.missingUsageDescription(key: key)
            }
        }
    }

    static func fireAndAwaitChange(
        shim: LocationShim,
        fire: @Sendable (LocationShim) async -> Void
    ) async {
        let changes = await shim.authorizationChanges()
        await fire(shim)
        for await _ in changes {
            break
        }
    }
}

extension LocationWhenInUsePermission {
    static func adapter(
        shim: LocationShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> LocationWhenInUsePermission {
        let coalescer = RequestCoalescer<LocationWhenInUseStatus>()
        let hub = StatusHub<LocationWhenInUseStatus>()
        let publishCurrent: @Sendable () async -> LocationWhenInUseStatus = {
            let status = await LocationWhenInUseStatus(
                native: shim.authorizationStatus(),
                nativeAccuracy: shim.accuracyAuthorization()
            )
            await hub.publish(status)
            return status
        }
        Task {
            for await _ in await shim.authorizationChanges() {
                _ = await publishCurrent()
            }
        }
        return LocationWhenInUsePermission(
            status: publishCurrent,
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        let current = await shim.authorizationStatus()
                        guard current == .notDetermined else {
                            let status = await LocationWhenInUseStatus(
                                native: current,
                                nativeAccuracy: shim.accuracyAuthorization()
                            )
                            await hub.publish(status)
                            return status
                        }
                        try LocationRequestFlow.validate(
                            keys: [LocationRequestFlow.whenInUseKey],
                            infoPlist: infoPlist
                        )
                        await LocationRequestFlow.fireAndAwaitChange(shim: shim) {
                            await $0.requestWhenInUseAuthorization()
                        }
                        return await publishCurrent()
                    }
                } ifCancelled: {
                    await LocationWhenInUseStatus(
                        native: shim.authorizationStatus(),
                        nativeAccuracy: shim.accuracyAuthorization()
                    )
                }
            },
            updates: { await hub.stream() }
        )
    }
}

extension LocationAlwaysPermission {
    static func adapter(
        shim: LocationShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> LocationAlwaysPermission {
        let coalescer = RequestCoalescer<LocationAlwaysStatus>()
        let hub = StatusHub<LocationAlwaysStatus>()
        let publishCurrent: @Sendable () async -> LocationAlwaysStatus = {
            let status = await LocationAlwaysStatus(
                native: shim.authorizationStatus(),
                nativeAccuracy: shim.accuracyAuthorization()
            )
            await hub.publish(status)
            return status
        }
        Task {
            for await _ in await shim.authorizationChanges() {
                _ = await publishCurrent()
            }
        }
        return LocationAlwaysPermission(
            status: publishCurrent,
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        let current = await shim.authorizationStatus()
                        switch current {
                        case .notDetermined:
                            try LocationRequestFlow.validate(
                                keys: [
                                    LocationRequestFlow.whenInUseKey,
                                    LocationRequestFlow.alwaysKey,
                                ],
                                infoPlist: infoPlist
                            )
                            await LocationRequestFlow.fireAndAwaitChange(shim: shim) {
                                await $0.requestAlwaysAuthorization()
                            }
                            return await publishCurrent()
                        case .authorizedWhenInUse:
                            try LocationRequestFlow.validate(
                                keys: [
                                    LocationRequestFlow.whenInUseKey,
                                    LocationRequestFlow.alwaysKey,
                                ],
                                infoPlist: infoPlist
                            )
                            await shim.requestAlwaysAuthorization()
                            return await publishCurrent()
                        default:
                            let status = await LocationAlwaysStatus(
                                native: current,
                                nativeAccuracy: shim.accuracyAuthorization()
                            )
                            await hub.publish(status)
                            return status
                        }
                    }
                } ifCancelled: {
                    await LocationAlwaysStatus(
                        native: shim.authorizationStatus(),
                        nativeAccuracy: shim.accuracyAuthorization()
                    )
                }
            },
            updates: { await hub.stream() }
        )
    }
}
