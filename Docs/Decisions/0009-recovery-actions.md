# ADR 0009: Recovery Placement and Execution

## Context

ADR 0003 established that recovery is explicit and application-controlled. It did not decide where recovery is described or how limited-selection management is invoked. The photo library's limited-selection picker requires UIKit presentation bridging, while contact selection management has native SwiftUI support.

## Decision

- Each status describes its available recovery action, because recovery depends on state
- `openSettings` executes on the client
- Notification recovery may use the sanctioned notification-settings URL where available; private URL schemes are never used
- Limited-selection management is executed through the SwiftUI layer, which owns any UIKit presentation bridging
- No recovery action ever executes automatically

## Consequences

- Generic UI can render a recovery affordance from status alone
- UIKit bridging stays inside the SwiftUI layer rather than leaking into the domain
- Pure UIKit consumers must build their own presentation for limited-selection management in version 1
