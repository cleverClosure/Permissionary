# ADR 0013: Request Coordination

## Context

API.md requires deterministic behavior for concurrent requests:
duplicates coalesce, incompatible prompts serialize, all waiting
callers receive the same snapshot, cancellation stops waiting without
dismissing a visible prompt, and continuations resume exactly once.
The adapters implemented so far execute their native flows directly,
so two concurrent calls could trigger two native requests.

## Decision

- Each capability's request runs through a per-capability coalescer:
  an actor holding a registry of waiting continuations and at most one
  running operation. Callers join the in-flight operation; the last
  result is delivered to every waiter
- The running operation executes in its own task, detached from every
  caller, so no caller's cancellation can cancel the shared native
  request
- A cancelled caller is unregistered and receives a freshly read
  current status instead; the registry's remove-then-resume discipline
  makes double resumption impossible
- A failed operation delivers the same error to every waiter
- One prompt serializer per client gates operation execution across
  all capabilities: operations run one at a time, queued in arrival
  order. Joining an in-flight operation does not touch the serializer,
  so coalesced callers cannot deadlock it
- The serializer releases on error as well as success
- Requests that will not prompt still pass through the serializer;
  they hold it only for the duration of a status read, which is not
  worth a bypass mechanism
- Coordination is internal: factories accept a coordination value,
  the live client shares one serializer across all capabilities, and
  the public API is unchanged

## Consequences

- Concurrent duplicate requests produce one native prompt and one
  answer, delivered uniformly
- Prompts from different capabilities appear one at a time in a
  deterministic order instead of stacking at the system's discretion
- Adapter contract tests are unaffected; coordination behavior is
  tested separately with gated scripted shims
- A capability constructed without an explicit coordination value is
  still coalesced with itself, just not serialized against other
  capabilities; the live client always passes the shared value
