# Architecture

## Package shape

Start with one public Swift Package product.

```text
Sources/Permissionary/
├── Domain/
├── SystemAdapters/
├── Coordination/
├── Configuration/
└── SwiftUI/

Tests/PermissionaryTests/

Examples/PermissionaryDemo/
```

Do not split the package into multiple public modules until a concrete consumer need appears.

A single product links every supported system framework. Linking alone has no privacy or review consequences; usage-description keys are required only for capabilities an application actually requests. State this explicitly in consumer documentation.

## Layers

### Domain

Contains:

- Public permission states
- Permission-specific status types
- Recovery actions
- Public errors
- Injectable client types
- Status update streams for observation

Domain code must not depend on SwiftUI.

### System adapters

One adapter per Apple framework:

- AVFoundation
- CoreLocation
- UserNotifications
- Photos
- Contacts
- AVFAudio
- AppTrackingTransparency

Each adapter owns:

- Native-state reading
- Native-to-library mapping
- Request execution
- Framework-specific delegate or callback handling
- Configuration validation

Each adapter separates:

- Pure mapping functions from native states to library states
- A thin native shim that performs the real framework calls
- Behavior glue connecting the shim to coordination

The native shim is injectable. Contract and coordination tests run against scripted shims; only the real shim requires device verification.

### Coordination

Coordinates system requests across adapters.

Responsibilities:

- Coalesce duplicate requests
- Serialize incompatible prompts
- Handle waiting callers
- Prevent continuation leaks
- Define cancellation behavior
- Refresh final status after callbacks complete

Use actors where mutable cross-task state is required.

### Configuration

Contains:

- Info.plist validation
- Availability checks
- Capability-specific request configuration
- Debug diagnostics

The host application owns all localized usage-description text.

### SwiftUI

Contains:

- Environment integration
- Observable state models
- Refresh helpers
- Optional view modifiers
- Test overrides

SwiftUI code may depend on the domain layer but should not contain framework-specific permission logic.

## Dependency direction

```text
SwiftUI
   ↓
Domain ← Coordination
   ↑         ↑
Configuration System Adapters
```

System framework types should not leak across the package.

## Public API strategy

The primary API is an injectable client.

Provide:

- A live implementation
- Lightweight test implementations
- Explicit dependency injection
- No required global mutable singleton

A convenience static value may exist, but it must not prevent isolated tests.

## Concurrency rules

- Compile in Swift 6 language mode
- Enable strict concurrency checks
- Public value types are immutable and `Sendable`
- UI operations are `@MainActor`
- Mutable request coordination is actor-isolated
- Framework delegates have explicit isolation
- Callback APIs use checked continuations
- Avoid `@unchecked Sendable`
- Resume every continuation exactly once
- Keep the package default isolation `nonisolated`; do not adopt module-wide main-actor isolation
- Track the current stable Swift toolchain and revisit isolation defaults as the language evolves

## Request model

Recommended behavior:

1. Read current state.
2. If no system request is possible, return the current snapshot.
3. Validate required configuration.
4. Join an existing request for the same capability, if present.
5. Otherwise enter the request coordinator.
6. Execute the native request.
7. Read the final native status.
8. Map it to a library snapshot.
9. Resume all waiting callers with the same result.

## Lifecycle handling

Some permissions depend on application lifecycle state.

The architecture must define:

- Which operations require an active application
- Which calls run on the main actor
- How requests behave while the app is inactive
- How state is refreshed after returning from Settings
- Which Settings changes terminate a suspended app, and how flows recover after the forced relaunch
- How delegate-backed managers remain alive

## Dependencies

Version 1 has no third-party runtime dependencies.

Development-only tooling may be added when it provides clear value and does not affect consumers.

## Privacy

The library should not:

- Collect analytics
- Send network requests
- Store permission decisions
- Infer user behavior
- Include unrelated required-reason APIs

Before release, audit the APIs the package actually uses and ship an accurate privacy manifest. The expected outcome for this library is a manifest declaring no data collection and no required-reason API use.

Do not copy a speculative manifest from another package.

## Demo application

The demo app is part of the architecture, not merely marketing.

It should provide:

- One screen per permission
- Current normalized status
- Framework-specific details
- Request button
- Settings recovery button
- Refresh button
- Required configuration visibility
- Instructions for resetting test state
