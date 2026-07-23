# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Until 1.0.0, minor
releases may contain breaking changes; pin an exact version.

## [Unreleased]

### Added

- Nine capabilities — camera, microphone, photos read/write, photos add-only, contacts,
  location when-in-use, location always, notifications, and tracking — each exposing
  `status()`, `request()`, and an `updates()` stream with a typed status.
- Normalized `PermissionAuthorization` plus per-capability detail: location accuracy,
  notification grant, and a Sendable notification-settings snapshot.
- Explicit recovery model: statuses suggest `openSettings` or `manageLimitedSelection`; the
  client's `openSettings` operation opens the application's Settings page.
- Configuration validation: requests throw a descriptive `PermissionError` for missing
  usage-description keys instead of letting the system terminate the process.
- Request coordination: duplicate requests per capability coalesce into one native prompt
  with a shared result; prompts across capabilities are serialized.
- SwiftUI layer: `\.permissions` environment entry defaulting to the live client and an
  `@Observable` model per capability; the live client re-reads all statuses when the
  application becomes active.
- Injectable `PermissionsClient` built from replaceable operations, with no global singleton.
- Privacy manifest declaring no tracking, no data collection, and no required-reason APIs.
- Demo app exercising every capability and a device verification checklist gating releases.
