# ADR 0005: Package Structure

## Context

Separate modules for core APIs, SwiftUI, and testing could improve isolation, but would also increase packaging and import complexity before real consumer needs are known.

## Decision

Version 1 uses one public Swift Package product with internal folders for:

- Domain
- System adapters
- Coordination
- Configuration
- SwiftUI

There are no external runtime dependencies.

## Consequences

- Installation and imports remain simple
- Internal architecture can still be clean
- Modules may be split in a future major version if concrete use cases justify it
