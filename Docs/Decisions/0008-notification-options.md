# ADR 0008: Notification Request Options and Provisional Authorization

## Context

Notification authorization is parameterized by requested options. Requesting provisional authorization first and full authorization later is a legitimate flow, so options cannot be fixed at client construction. Provisional and ephemeral authorization also need normalized representations, and the native settings object is not Sendable.

## Decision

- Request options are a parameter on each request with a default of alert, sound, and badge
- Provisional authorization is normalized as `limited`; typed details preserve the exact native state
- Ephemeral authorization is normalized as `authorized`; typed details preserve the exact native state
- The status carries a Sendable copy of detailed notification settings; the native settings object is never exposed

## Consequences

- Multi-step provisional flows are expressible
- Generic UI treats provisional delivery as a partial grant
- The details type must be maintained as the system adds notification settings
