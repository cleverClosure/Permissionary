# ADR 0002: Permission State Model

## Context

Apple permission frameworks expose different states. A single `isGranted` Boolean would lose important distinctions such as limited, provisional, restricted, when-in-use, and always.

## Decision

Use two layers:

1. A small normalized authorization state for generic UI
2. Typed permission-specific details for framework semantics

Denied, restricted, and limited outcomes are returned as normal values.

## Consequences

- Generic UI remains possible
- Framework-specific behavior is preserved
- Public types are more explicit
- The API is slightly larger than a Boolean-based wrapper
