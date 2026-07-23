//
//  Microphone.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import AVFAudio

struct MicrophoneShim: Sendable {
    var recordPermission: @Sendable () -> AVAudioApplication.recordPermission
    var requestRecordPermission: @Sendable () async -> Bool

    static let live = MicrophoneShim(
        recordPermission: { AVAudioApplication.shared.recordPermission },
        requestRecordPermission: { await AVAudioApplication.requestRecordPermission() }
    )
}

extension MicrophoneStatus {
    init(native: AVAudioApplication.recordPermission) {
        switch native {
        case .undetermined: self.init(authorization: .notDetermined, recovery: nil)
        case .granted: self.init(authorization: .authorized, recovery: nil)
        case .denied: self.init(authorization: .denied, recovery: .openSettings)
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "microphone")
            self.init(authorization: .denied, recovery: .openSettings)
        }
    }
}

extension MicrophonePermission {
    static func adapter(
        shim: MicrophoneShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> MicrophonePermission {
        let coalescer = RequestCoalescer<MicrophoneStatus>()
        let hub = StatusHub<MicrophoneStatus>()
        return MicrophonePermission(
            status: {
                let status = MicrophoneStatus(native: shim.recordPermission())
                await hub.publish(status)
                return status
            },
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        let status = try await PromptOnceRequest.run(
                            usageDescriptionKey: "NSMicrophoneUsageDescription",
                            infoPlist: infoPlist,
                            readNative: shim.recordPermission,
                            canPrompt: { $0 == .undetermined },
                            prompt: { _ = await shim.requestRecordPermission() },
                            makeStatus: { MicrophoneStatus(native: $0) }
                        )
                        await hub.publish(status)
                        return status
                    }
                } ifCancelled: {
                    MicrophoneStatus(native: shim.recordPermission())
                }
            },
            updates: { await hub.stream() }
        )
    }
}
