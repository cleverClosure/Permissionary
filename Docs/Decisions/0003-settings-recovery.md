# ADR 0003: Settings Recovery

## Context

After denial, Apple frameworks often cannot show the system prompt again. Applications may need to guide users to Settings.

Automatically opening Settings is surprising and prevents the host application from providing context.

## Decision

- The library never opens Settings automatically
- Permission snapshots may describe an available recovery action
- The host application explicitly invokes `openSettings()`
- Restricted does not automatically imply that Settings can help

## Consequences

- Recovery behavior is predictable
- Product-specific explanation remains in the application
- Consumers must implement the final recovery interaction
