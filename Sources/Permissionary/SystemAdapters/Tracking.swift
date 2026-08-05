//
//  Tracking.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import AppTrackingTransparency

struct TrackingShim: Sendable {
    var authorizationStatus: @Sendable () -> ATTrackingManager.AuthorizationStatus
    var requestAuthorization: @Sendable () async -> Void

    static let live = TrackingShim(
        authorizationStatus: { ATTrackingManager.trackingAuthorizationStatus },
        requestAuthorization: { _ = await ATTrackingManager.requestTrackingAuthorization() }
    )
}

extension TrackingStatus {
    init(native: ATTrackingManager.AuthorizationStatus) {
        switch native {
        case .notDetermined: self.init(authorization: .notDetermined, recovery: nil)
        case .authorized: self.init(authorization: .authorized, recovery: nil)
        case .denied: self.init(authorization: .denied, recovery: .openSettings)
        case .restricted: self.init(authorization: .restricted, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(rawValue: Int(native.rawValue), capability: "tracking")
            self.init(authorization: .denied, recovery: .openSettings)
        }
    }
}

extension TrackingPermission {
    static func adapter(
        shim: TrackingShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> TrackingPermission {
        let coalescer = RequestCoalescer<TrackingStatus>()
        let hub = StatusHub<TrackingStatus>()
        return TrackingPermission(
            status: {
                let status = TrackingStatus(native: shim.authorizationStatus())
                await hub.publish(status)
                return status
            },
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        let status = try await PromptOnceRequest.run(
                            usageDescriptionKey: UsageDescriptionKey.tracking,
                            infoPlist: infoPlist,
                            readNative: shim.authorizationStatus,
                            canPrompt: { $0 == .notDetermined },
                            prompt: shim.requestAuthorization,
                            makeStatus: { TrackingStatus(native: $0) }
                        )
                        await hub.publish(status)
                        return status
                    }
                } ifCancelled: {
                    TrackingStatus(native: shim.authorizationStatus())
                }
            },
            updates: { await hub.stream() }
        )
    }
}
