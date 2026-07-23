//
//  CoordinationTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AVFAudio
import AVFoundation
import Synchronization
import Testing

@testable import Permissionary

private final class Gate: Sendable {
    private struct State {
        var isOpen = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = Mutex(State())

    func open() {
        let waiters = state.withLock { state in
            state.isOpen = true
            let waiting = state.waiters
            state.waiters = []
            return waiting
        }
        for waiter in waiters {
            waiter.resume()
        }
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            let isAlreadyOpen = state.withLock { state in
                guard !state.isOpen else { return true }
                state.waiters.append(continuation)
                return false
            }
            if isAlreadyOpen {
                continuation.resume()
            }
        }
    }
}

private final class EventLog: Sendable {
    private let events = Mutex<[String]>([])

    func record(_ event: String) {
        events.withLock { $0.append(event) }
    }

    var all: [String] {
        events.withLock { $0 }
    }
}

@Suite(.timeLimit(.minutes(1)))
struct CoordinationTests {
    private func makeGatedCamera(
        script: ShimScript<AVAuthorizationStatus>,
        coordination: RequestCoordination,
        started: Gate,
        release: Gate,
        log: EventLog = EventLog(),
        usageDescription: String? = "Takes photos"
    ) -> CameraPermission {
        .adapter(
            shim: CameraShim(
                authorizationStatus: { script.nextState() },
                requestAccess: {
                    script.recordPrompt()
                    log.record("camera.start")
                    started.open()
                    await release.wait()
                    log.record("camera.end")
                    return true
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in usageDescription }),
            coordination: coordination
        )
    }

    @Test("Concurrent requests produce one native prompt and one shared answer")
    func concurrentRequestsShareOnePrompt() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .authorized)
        let started = Gate()
        let release = Gate()
        let camera = makeGatedCamera(
            script: script,
            coordination: RequestCoordination(),
            started: started,
            release: release
        )

        let first = Task { try await camera.request() }
        await started.wait()
        let second = Task { try await camera.request() }
        for _ in 0..<100 {
            await Task.yield()
        }
        release.open()

        let firstStatus = try await first.value
        let secondStatus = try await second.value
        #expect(firstStatus == CameraStatus(authorization: .authorized, recovery: nil))
        #expect(secondStatus == CameraStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("A cancelled waiter gets the current status while others get the answer")
    func cancelledWaiterLeavesOthersUnaffected() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .notDetermined, .authorized)
        let started = Gate()
        let release = Gate()
        let camera = makeGatedCamera(
            script: script,
            coordination: RequestCoordination(),
            started: started,
            release: release
        )

        let first = Task { try await camera.request() }
        await started.wait()
        let second = Task { try await camera.request() }
        for _ in 0..<100 {
            await Task.yield()
        }
        second.cancel()
        let secondStatus = try await second.value
        #expect(secondStatus.authorization == .notDetermined)

        release.open()
        let firstStatus = try await first.value
        #expect(firstStatus.authorization == .authorized)
        #expect(script.promptCount == 1)
    }

    @Test("A failed operation delivers the same error to every caller")
    func errorsPropagateToAllCallers() async {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined)
        let camera = CameraPermission.adapter(
            shim: CameraShim(
                authorizationStatus: { script.nextState() },
                requestAccess: {
                    script.recordPrompt()
                    return true
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in nil }),
            coordination: RequestCoordination()
        )

        let first = Task { try await camera.request() }
        let second = Task { try await camera.request() }
        let expected = PermissionError.missingUsageDescription(key: "NSCameraUsageDescription")
        await #expect(throws: expected) { _ = try await first.value }
        await #expect(throws: expected) { _ = try await second.value }
        #expect(script.promptCount == 0)
    }

    @Test("Prompts from different capabilities run one at a time, in order")
    func promptsSerializeAcrossCapabilities() async throws {
        let coordination = RequestCoordination()
        let log = EventLog()
        let cameraScript = ShimScript<AVAuthorizationStatus>(.notDetermined, .authorized)
        let started = Gate()
        let release = Gate()
        let camera = makeGatedCamera(
            script: cameraScript,
            coordination: coordination,
            started: started,
            release: release,
            log: log
        )

        let microphoneScript = ShimScript<AVAudioApplication.recordPermission>(
            .undetermined,
            .granted
        )
        let microphone = MicrophonePermission.adapter(
            shim: MicrophoneShim(
                recordPermission: { microphoneScript.nextState() },
                requestRecordPermission: {
                    log.record("microphone.start")
                    log.record("microphone.end")
                    return true
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in "Records audio" }),
            coordination: coordination
        )

        let cameraTask = Task { try await camera.request() }
        await started.wait()
        let microphoneTask = Task { try await microphone.request() }
        for _ in 0..<100 {
            await Task.yield()
        }
        #expect(!log.all.contains("microphone.start"))

        release.open()
        _ = try await cameraTask.value
        _ = try await microphoneTask.value
        #expect(log.all == ["camera.start", "camera.end", "microphone.start", "microphone.end"])
    }

    @Test("The serializer releases after a failed operation")
    func serializerReleasesAfterFailure() async throws {
        let coordination = RequestCoordination()
        let cameraScript = ShimScript<AVAuthorizationStatus>(.notDetermined)
        let camera = CameraPermission.adapter(
            shim: CameraShim(
                authorizationStatus: { cameraScript.nextState() },
                requestAccess: { true }
            ),
            infoPlist: InfoPlistReader(string: { _ in nil }),
            coordination: coordination
        )
        await #expect(throws: PermissionError.self) { _ = try await camera.request() }

        let microphoneScript = ShimScript<AVAudioApplication.recordPermission>(
            .undetermined,
            .granted
        )
        let microphone = MicrophonePermission.adapter(
            shim: MicrophoneShim(
                recordPermission: { microphoneScript.nextState() },
                requestRecordPermission: { true }
            ),
            infoPlist: InfoPlistReader(string: { _ in "Records audio" }),
            coordination: coordination
        )
        let status = try await microphone.request()
        #expect(status.authorization == .authorized)
    }
}
