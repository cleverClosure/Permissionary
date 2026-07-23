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
    static func adapter(shim: TrackingShim, infoPlist: InfoPlistReader) -> TrackingPermission {
        TrackingPermission(
            status: { TrackingStatus(native: shim.authorizationStatus()) },
            request: {
                try await PromptOnceRequest.run(
                    usageDescriptionKey: "NSUserTrackingUsageDescription",
                    infoPlist: infoPlist,
                    readNative: shim.authorizationStatus,
                    canPrompt: { $0 == .notDetermined },
                    prompt: shim.requestAuthorization,
                    makeStatus: { TrackingStatus(native: $0) }
                )
            }
        )
    }
}
