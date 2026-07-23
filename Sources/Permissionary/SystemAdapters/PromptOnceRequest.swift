//
//  PromptOnceRequest.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import os

enum PromptOnceRequest {
    static func run<Native: Sendable, Status: Sendable>(
        usageDescriptionKey: String,
        infoPlist: InfoPlistReader,
        readNative: @Sendable () -> Native,
        canPrompt: @Sendable (Native) -> Bool,
        prompt: @Sendable () async -> Void,
        makeStatus: @Sendable (Native) -> Status
    ) async throws -> Status {
        let current = readNative()
        guard canPrompt(current) else { return makeStatus(current) }
        guard let description = infoPlist.string(usageDescriptionKey), !description.isEmpty else {
            throw PermissionError.missingUsageDescription(key: usageDescriptionKey)
        }
        await prompt()
        return makeStatus(readNative())
    }
}

func debugLogUnknownNativeState(rawValue: Int, capability: String) {
    #if DEBUG
        Logger(subsystem: "Permissionary", category: "mapping")
            .error("Unknown native \(capability, privacy: .public) state: \(rawValue)")
    #endif
}
