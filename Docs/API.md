# API Design

## Design objectives

The public API should be:

- Predictable
- Explicit
- Swift 6-safe
- Testable
- Small
- SwiftUI-friendly
- Honest about differences between Apple frameworks

## Core separation

Reading status and requesting permission are separate operations.

```swift
func status() async -> Status
func request() async throws -> Status
```

`status()` must never present a system prompt.

`request()` may present a system prompt only when the underlying framework permits it.

Both operations are `async` even where the underlying framework API is synchronous. This keeps call sites uniform, allows internal actor hops, and matches frameworks that only expose asynchronous reads.

## Permission state

Permission state must not be represented as a Boolean.

A normalized authorization layer should support generic application UI:

```swift
public enum PermissionAuthorization: Sendable, Equatable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
    case unavailable
}
```

Case semantics:

- `limited` is any partial grant that permits reduced functionality: limited photo or contact selection, provisional notification delivery, or when-in-use access viewed from the Always capability
- `unavailable` means the capability's API cannot be used in the current environment; it does not describe hardware presence
- Unknown future native states map to the safest matching case and never crash

Framework-specific information is preserved in concrete, capability-specific status types (ADR 0006):

```swift
public struct CameraStatus: Sendable, Equatable {
    public let authorization: PermissionAuthorization
    public let recovery: PermissionRecovery?
    // Capability-specific detail fields
}
```

A minimal protocol allows generic UI over any capability:

```swift
public protocol PermissionStatus: Sendable {
    var authorization: PermissionAuthorization { get }
    var recovery: PermissionRecovery? { get }
}
```

There is no public generic status container.

The exact cases and detail fields may change after the permission matrix is complete.

## Permission-specific APIs

Each capability should expose a typed API.

Conceptual example:

```swift
public struct CameraPermission: Sendable {
    public func status() async -> CameraStatus
    public func request() async throws -> CameraStatus
}
```

Capabilities with materially different semantics should remain separate:

- Location When In Use
- Location Always
- Photos Read/Write
- Photos Add Only

Location status types include accuracy authorization in their details. The Always capability reports a when-in-use grant as `limited` (ADR 0007).

## Errors

The following are normal results and should not throw:

- User denied access
- Access is restricted
- Limited access was granted
- Permission was already determined
- The system refused to show another prompt

Errors should be reserved for exceptional conditions. Configuration validation exists to fail with a descriptive error before the system would otherwise terminate the process, as happens when requesting camera access without a usage description:

```swift
public enum PermissionError: Error, Sendable, Equatable {
    case missingUsageDescription(key: String)
    case invalidConfiguration(reason: String)
    case unsupported
    case underlying(description: String)
}
```

Do not expose non-Sendable framework error types directly through the public API.

## Recovery

Recovery is explicit and application-controlled.

```swift
public enum PermissionRecovery: Sendable, Equatable {
    case openSettings
    case manageLimitedSelection
}
```

The library must not automatically open Settings after a denied request.

```swift
let result = try await permissions.camera.request()

if result.recovery == .openSettings {
    await permissions.openSettings()
}
```

`.restricted` must not automatically imply that Settings can fix the problem.

Notification recovery deep-links to the application's notification settings through the client's `openNotificationSettings`, which uses the sanctioned system URL. Private URL schemes are never used.

Executing `manageLimitedSelection` is capability-specific: the photo library picker requires UIKit presentation bridging, owned by the SwiftUI layer through the `limitedPhotoLibraryPicker(isPresented:)` modifier, while contact selection management uses the system's native SwiftUI entry point (ADR 0009).

## Permission client

The primary entry point should be injectable.

Conceptual design:

```swift
public struct PermissionsClient: Sendable {
    public var camera: CameraPermission
    public var locationWhenInUse: LocationWhenInUsePermission
    public var locationAlways: LocationAlwaysPermission
    public var notifications: NotificationsPermission
    public var photosReadWrite: PhotosReadWritePermission
    public var photosAddOnly: PhotosAddOnlyPermission
    public var contacts: ContactsPermission
    public var microphone: MicrophonePermission
    public var tracking: TrackingPermission
    public var openSettings: @Sendable () async -> Void
    public var openNotificationSettings: @Sendable () async -> Void
}
```

Provide:

- `.live`
- Easy test construction
- No mandatory global singleton

## Request coordination

The library must define deterministic behavior for concurrent calls.

Recommended rules:

- Duplicate requests for the same capability are coalesced
- Incompatible simultaneous system prompts are serialized
- All waiting callers receive the same final snapshot
- Cancellation stops waiting for the caller
- Caller cancellation does not attempt to dismiss an already visible system prompt
- Continuations are resumed exactly once

## Actor isolation

Recommended isolation model:

- Immutable domain values are `Sendable`
- Permission coordinators use actors where mutable coordination is required
- UI and application-lifecycle operations use `@MainActor`
- Framework delegates are isolated explicitly
- Avoid `@unchecked Sendable`

Do not mark the entire library `@MainActor` only to silence compiler diagnostics.

## SwiftUI integration

The SwiftUI surface should remain small.

### Environment injection

```swift
@Environment(\.permissions) private var permissions
```

### Observable permission state

Provide an `@Observable` model per capability, built on a domain-level status update stream (ADR 0010), that:

- Reads the initial status
- Publishes updates
- Requests explicitly
- Refreshes after returning from Settings, including after a forced relaunch
- Supports dependency injection

No property wrapper is provided in version 1.

### Environment default

`\.permissions` defaults to the live client. This is safe because status reads have no side effects, but previews and tests should inject deterministic fakes.

### Explicit requests

Requests must be initiated by an explicit application action.

Avoid APIs that automatically trigger a system prompt from:

- `onAppear`
- A view initializer
- Environment insertion
- Passive observation

### Scene refresh

The live client re-reads every capability when the application becomes
active and publishes the results through the domain update streams, so
observable models refresh automatically without per-view modifiers
(ADR 0014). This is safe because status reads never prompt.

Injected clients receive no automatic feeding. Tests and previews drive
state explicitly, and `refresh()` on any model re-reads on demand:

```swift
.onChange(of: scenePhase) { _, phase in
    if phase == .active {
        Task {
            await model.refresh()
        }
    }
}
```

No modifier automates requesting; requests always remain explicit.

## Configuration validation

Before requesting a permission, the live implementation should validate required configuration where practical.

Examples:

- Required Info.plist usage-description keys
- Capability availability
- Required request options
- Supported OS behavior

Configuration failures should be descriptive and actionable.

A standalone diagnostic entry point may be provided so applications can surface configuration problems in debug builds before any request is made.

## Naming rules

- The module is named Permissionary; public types use capability-oriented names without brand prefixes
- Prefer capability names over framework names
- Avoid abbreviations in public symbols
- Use nouns for state
- Use verbs for actions
- Do not expose unnecessary Apple-framework types
- Preserve Apple terminology where changing it would cause confusion

## Resolved API questions

Previously open questions, now decided:

1. Status values use concrete per-capability types plus a minimal shared protocol; no generics (ADR 0006)
2. There is no shared public request protocol; uniform naming provides consistency (ADR 0006)
3. Notification options are a per-request parameter with a default (ADR 0008)
4. Location is modeled as two capabilities; the Always capability reports when-in-use as `limited` (ADR 0007)
5. Recovery is described on each status and executed by the client and SwiftUI layers (ADR 0009)
6. Unknown native states map to a safe normalized case and stay diagnosable in debug builds; there is no public `unknown` case (see the permission matrix)
7. The SwiftUI layer ships an observable model over a domain status stream; no property wrapper (ADR 0010)

## Remaining open questions

1. Whether the location adapter can adopt session-based system APIs without breaking the one-shot request model (deferred by ADR 0007)
2. Exact typed detail fields per capability, pending matrix verification against the current SDK
