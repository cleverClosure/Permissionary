# ADR 0012: Location Request Semantics

## Context

ADR 0007 fixed the capability split and the delegate-based manager.
The adapter still had to define how a one-shot `request()` maps onto
Core Location's callback-driven authorization flow, what the Always
upgrade does when the system declines to prompt again, and how accuracy
authorization appears in typed details.

Two Core Location behaviors shape the design. First, authorization
outcomes arrive through a delegate callback, not a return value, so a
request must observe the change stream. Second, the Always upgrade
prompt is shown at most once per install and no public API reveals
whether it has been used; a request fired after that point may produce
no callback at all.

## Decision

- Requests subscribe to authorization changes before firing the native
  request, so an immediate callback cannot be missed
- From not determined, both capabilities fire the native request and
  await the next authorization change; every possible answer to a
  first prompt changes the status, so the change is guaranteed
- From when-in-use, the Always capability fires the native upgrade
  request and returns the current snapshot immediately, without
  awaiting a change; whether the system will prompt is unknowable, and
  waiting could hang forever. The definitive outcome is observed
  through subsequent status reads
- Caller cancellation while awaiting a change stops the wait and
  returns the freshly read current snapshot; it never dismisses a
  visible system prompt
- Accuracy authorization appears in typed details as an optional value
  populated only when access is granted; without a grant it carries no
  information
- An unknown accuracy value maps to reduced, never overstating
  precision
- The When In Use capability requires `NSLocationWhenInUseUsageDescription`;
  the Always capability additionally requires
  `NSLocationAlwaysAndWhenInUseUsageDescription`, and validation names
  the first missing key
- System-wide Location Services off surfaces as denied, exactly as the
  system reports it; the adapter adds no separate services probe

## Consequences

- No request path can hang, and none returns a fabricated state
- An Always upgrade caller sees `limited` until the user answers, then
  the true state on the next read; documentation and the demo app must
  make this visible
- Contract tests can script every path deterministically, including
  the immediate-callback race and cancellation
- Adopting session-based APIs later (deferred by ADR 0007) only has to
  preserve these observable semantics
