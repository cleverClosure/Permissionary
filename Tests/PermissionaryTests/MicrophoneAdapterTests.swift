//
//  MicrophoneAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AVFAudio
import Testing

@testable import Permissionary

struct MicrophoneAdapterTests {
    private func makeMicrophone(
        script: ShimScript<AVAudioApplication.recordPermission>,
        grants: Bool = true,
        usageDescription: String? = "Records audio"
    ) -> MicrophonePermission {
        .adapter(
            shim: MicrophoneShim(
                recordPermission: { script.nextState() },
                requestRecordPermission: {
                    script.recordPrompt()
                    return grants
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in usageDescription })
        )
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            MicrophoneStatus(native: .undetermined)
                == MicrophoneStatus(authorization: .notDetermined, recovery: nil)
        )
        #expect(
            MicrophoneStatus(native: .granted)
                == MicrophoneStatus(authorization: .authorized, recovery: nil)
        )
        #expect(
            MicrophoneStatus(native: .denied)
                == MicrophoneStatus(authorization: .denied, recovery: .openSettings)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(AVAudioApplication.recordPermission(rawValue: 999))
        #expect(
            MicrophoneStatus(native: unknown)
                == MicrophoneStatus(authorization: .denied, recovery: .openSettings)
        )
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = ShimScript<AVAudioApplication.recordPermission>(.undetermined)
        let microphone = makeMicrophone(script: script)
        _ = await microphone.status()
        #expect(script.promptCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = ShimScript<AVAudioApplication.recordPermission>(.undetermined, .granted)
        let microphone = makeMicrophone(script: script)
        let status = try await microphone.request()
        #expect(status == MicrophoneStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = ShimScript<AVAudioApplication.recordPermission>(.undetermined, .denied)
        let status = try await makeMicrophone(script: script, grants: false).request()
        #expect(status == MicrophoneStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = ShimScript<AVAudioApplication.recordPermission>(.denied)
        let microphone = makeMicrophone(script: script)
        let status = try await microphone.request()
        #expect(status.authorization == .denied)
        #expect(script.promptCount == 0)
    }

    @Test("A missing usage description fails before any prompt")
    func missingUsageDescription() async {
        let script = ShimScript<AVAudioApplication.recordPermission>(.undetermined)
        let microphone = makeMicrophone(script: script, usageDescription: nil)
        await #expect(
            throws: PermissionError.missingUsageDescription(key: "NSMicrophoneUsageDescription")
        ) {
            _ = try await microphone.request()
        }
        #expect(script.promptCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = ShimScript<AVAudioApplication.recordPermission>(.granted)
        let microphone = makeMicrophone(script: script, usageDescription: nil)
        let status = try await microphone.request()
        #expect(status.authorization == .authorized)
    }

    @Test("The status after the prompt is re-read, not assumed from the grant")
    func finalStateIsReRead() async throws {
        let script = ShimScript<AVAudioApplication.recordPermission>(.undetermined, .denied)
        let status = try await makeMicrophone(script: script, grants: true).request()
        #expect(status.authorization == .denied)
    }
}
