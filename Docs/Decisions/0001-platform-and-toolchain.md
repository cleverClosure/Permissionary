# ADR 0001: Platform and Toolchain

## Context

Supporting old iOS and Swift versions would increase branches, deprecated API usage, and concurrency complexity.

The project is intended to be a modern replacement rather than a compatibility library.

## Decision

- Minimum deployment target: iOS 18
- Language mode: Swift 6
- Distribution: Swift Package Manager only
- Development and releases use stable Xcode toolchains
- Stable releases do not depend on beta SDKs

## Consequences

- The implementation can use modern APIs and strict concurrency
- Adoption is limited to applications supporting iOS 18 or later
- The minimum platform may increase only in a future major release
