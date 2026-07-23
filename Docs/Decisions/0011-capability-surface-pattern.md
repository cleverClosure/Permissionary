# ADR 0011: Capability Surface Pattern

## Context

The first adapter implementations must fix the concrete shape of every
capability's public surface and the internal seam between domain,
adapters, and configuration. Six capabilities share one behavioral
shape: a synchronous native status read and a one-shot native request
that can prompt only from the not-determined state.

## Decision

- Each capability is a public struct of replaceable `@Sendable` async
  operations, mirroring `PermissionsClient`; call sites read like
  methods while tests and previews inject closures
- Each status type is a public immutable struct with a public
  memberwise initializer for easy test construction
- Native-to-library mapping is an internal initializer on the status
  type taking the native state; it is pure and exhaustively testable,
  including unknown future values
- Each adapter file owns its native shim: an internal struct of
  `@Sendable` closures that mirrors the native API exactly, with a
  `live` value as the only code touching the real framework
- The shared request flow lives in one internal generic runner: read,
  return early when no prompt is possible, validate the usage
  description, prompt, re-read, map; internal generics do not shape
  public API
- Usage-description validation runs only when a prompt will actually
  be attempted; requests that cannot prompt return the current
  snapshot without validation
- Unknown native states map to the per-capability safe case and are
  logged in debug builds; they never crash and never throw
- Request coordination (coalescing, prompt serialization) is not part
  of these adapters; it arrives with the coordination layer

## Consequences

- All prompt-once capabilities are structurally identical, so review
  and testing concentrate on their mapping tables and keys
- Contract tests script the shim and assert at the public surface,
  leaving everything between free to refactor
- Consumers construct fakes with plain initializers; no test library
  is required for basic injection
- The runner is the single place request semantics can change
