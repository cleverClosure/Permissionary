# ADR 0004: Concurrency and Isolation

## Context

Permission frameworks use callbacks, delegates, application lifecycle state, and sometimes main-thread-bound APIs.

Swift 6 requires explicit and correct concurrency isolation.

## Decision

- Public immutable values conform to `Sendable`
- Mutable request coordination is actor-isolated
- UI and application-lifecycle operations use `@MainActor`
- Callback APIs use checked continuations
- Duplicate requests for the same capability are coalesced
- Incompatible system prompts are serialized
- `@unchecked Sendable` is avoided

## Consequences

- Concurrency safety is designed in from the beginning
- Adapter implementations require careful isolation
- The library avoids duplicate prompts and continuation leaks
