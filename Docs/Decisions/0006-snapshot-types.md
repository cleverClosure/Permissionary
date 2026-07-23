# ADR 0006: Status Types

## Context

The API draft proposed a generic `PermissionSnapshot<Details>` container. A generic snapshot leaks its type parameter into every consuming signature, complicates the SwiftUI observation layer, and offers no benefit over concrete types for a fixed capability set. A shared request protocol across all permissions was also considered.

## Decision

- Each capability exposes a concrete, immutable, Sendable status type
- Concrete types conform to a minimal protocol exposing normalized authorization and recovery
- There is no public generic status container
- There is no shared public request protocol; uniform method naming provides consistency
- Internal protocols may be used where they reduce duplication without shaping public API

## Consequences

- Slightly more declared types
- Simpler call sites and observation models
- Generic UI remains possible through the shared protocol
- Capabilities can evolve their details independently without breaking others
