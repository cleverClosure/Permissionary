# ADR 0014: Observation Implementation

## Context

ADR 0010 decided that the domain exposes a status update stream per
capability and that the SwiftUI layer ships an `@Observable` model per
capability. Implementing that requires choosing where streams are fed,
how slow consumers are handled, and how models start and stop
observing.

## Decision

- Each capability gains an `updates` operation returning a stream of
  its typed status; an internal hub per adapter broadcasts to every
  subscriber
- Streams buffer only the newest value: status is a snapshot, and a
  consumer that fell behind needs the latest state, not history
- Every status read publishes its result, and a request's runner
  publishes the final snapshot exactly once; observers converge no
  matter which caller triggered the change
- The location adapters additionally feed their hubs from the
  authorization-change stream, the only push signal the system offers
- The live client re-reads every capability when the application
  becomes active, which feeds all hubs through the ordinary status
  path; a per-view refresh modifier is therefore unnecessary and not
  provided. Injected clients receive no automatic feeding; tests and
  previews publish by calling operations explicitly
- Models read the initial status and consume the update stream from
  initialization, because observation is side-effect-free; requests
  remain explicit methods. Deinitialization cancels the observation,
  which unsubscribes from the hub
- Models are `@MainActor`; status properties are read from view code

## Consequences

- Two models of the same capability converge through the domain
  stream without knowing about each other
- Activation refresh behavior lives in one place instead of scattered
  view modifiers
- Cold relaunches after a Settings kill work by construction: a fresh
  model's initial read is the recovery
- The capability initializers grow an `updates` parameter, a breaking
  change acceptable before 1.0
