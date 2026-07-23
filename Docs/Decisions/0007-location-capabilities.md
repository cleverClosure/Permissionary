# ADR 0007: Location Capability Modeling

## Context

Core Location exposes one authorization status covering two distinct product capabilities: when-in-use and always. Always authorization is an upgrade flow, can be granted provisionally, and a provisional grant cannot be distinguished from a final grant through public API. iOS 18 also introduced session-based location APIs alongside the delegate-based manager.

## Decision

- When In Use and Always are separate public capabilities
- The Always capability reports a when-in-use grant as the normalized `limited` state
- Typed details for both capabilities include accuracy authorization
- The library reports the system's authorization status truthfully, including provisional always, and documents the provisional window rather than guessing
- The version 1 adapter is built on the delegate-based manager because it matches a one-shot request model; session-based APIs will be re-evaluated once their authorization semantics are verified on device

## Consequences

- Consumers choose the capability that matches their feature
- The upgrade flow is explicit rather than hidden inside one state machine
- Reported always status may later downgrade when the system shows its deferred prompt; documentation must explain this
- Adopting session-based APIs later is an internal change as long as the public contract holds
