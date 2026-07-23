# ADR 0010: SwiftUI Observation Model

## Context

The SwiftUI integration could be a property wrapper, view modifiers, an observable model, or a combination. Property wrappers that own asynchronous state inside dynamic properties are error-prone. Observation should also not be SwiftUI-only, and some Settings changes terminate a suspended app, so recovery cannot rely solely on scene reactivation.

## Decision

- The domain layer exposes a status update stream per capability, fed by explicit refreshes and application-activation re-reads
- The SwiftUI layer ships an `@Observable` model per capability built on that stream
- No property wrapper is provided in version 1
- A convenience modifier may refresh on scene activation; nothing ever requests automatically
- The permissions environment value defaults to the live client; previews and tests inject fakes

## Consequences

- Non-SwiftUI code can observe the same stream
- The SwiftUI surface stays small and testable
- Automatic re-reads are safe because status reads never prompt
- Flows must tolerate cold relaunches after Settings changes that terminate the app
