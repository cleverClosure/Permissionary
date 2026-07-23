//
//  PermissionErrorTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

struct PermissionErrorTests {
    @Test("Errors distinguish their diagnostic payloads")
    func equality() {
        let camera = PermissionError.missingUsageDescription(key: "NSCameraUsageDescription")
        let microphone = PermissionError.missingUsageDescription(
            key: "NSMicrophoneUsageDescription"
        )
        #expect(camera != microphone)
        #expect(camera == .missingUsageDescription(key: "NSCameraUsageDescription"))
    }

    @Test("Errors are caught as typed values with their payload intact")
    func catchingPreservesPayload() {
        do {
            throw PermissionError.invalidConfiguration(
                reason: "temporary always requires when-in-use"
            )
        } catch let error as PermissionError {
            #expect(error == .invalidConfiguration(reason: "temporary always requires when-in-use"))
        } catch {
            Issue.record("PermissionError was not caught as its own type")
        }
    }

    @Test("Errors cross concurrency boundaries")
    func sendability() async {
        let error = PermissionError.unsupported
        let received = await Task.detached { error }.value
        #expect(received == .unsupported)
    }
}
