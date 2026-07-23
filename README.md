# Permissionary

A modern, SwiftUI-first permissions library for iOS, built with Swift 6 and async/await.

## Goals

- One consistent API for common iOS permissions
- Swift 6 concurrency safety
- Native async/await
- SwiftUI integration
- Explicit recovery after denial
- No legacy-platform compatibility burden
- No external runtime dependencies

## Requirements

- iOS 18+
- Swift 6
- Swift Package Manager
- Stable Xcode releases only

## Planned permissions

- Camera
- Location: When In Use
- Location: Always
- Notifications
- Photos: Read/Write
- Photos: Add Only
- Contacts
- Microphone
- App Tracking Transparency

The [capability roadmap](Docs/PROJECT.md#capability-roadmap) lists what is planned after version 1 and what is intentionally excluded.

## Proposed async API

```swift
let status = await permissions.camera.status()
let result = try await permissions.camera.request()
```

Reading the current status never presents a system prompt.

A denied or restricted result is returned as a normal permission state, not thrown as an error.

## Proposed SwiftUI API

```swift
@Environment(\.permissions) private var permissions
```

The SwiftUI layer will provide:

- Environment injection
- Observable permission state
- Explicit request actions
- Refresh after returning from Settings
- Test overrides

The library will not request permission automatically when a view appears.

## Settings recovery

The library will never open Settings automatically.

```swift
let result = try await permissions.camera.request()

if result.recovery == .openSettings {
    await permissions.openSettings()
}
```

The application remains responsible for explaining why the user should change a permission.

## Documentation

- [Project scope](Docs/PROJECT.md)
- [API design](Docs/API.md)
- [Permission matrix](Docs/PERMISSION_MATRIX.md)
- [Architecture](Docs/ARCHITECTURE.md)
- [Testing strategy](Docs/TESTING.md)
- [Architecture decisions](Docs/Decisions)
- [Contributing](CONTRIBUTING.md)

## Project status

Pre-development design phase. Public API is not yet stable.

Before 1.0, breaking changes may occur in any minor release. Pin an exact version if you adopt a 0.x release.

## License

MIT. See [LICENSE](LICENSE).
