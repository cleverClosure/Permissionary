# Contributing to Permissionary

Thanks for your interest in contributing.

## Project phase

Permissionary is in a pre-development design phase. The most valuable contributions right now are reviews of the design documents and real-world permission edge cases for the permission matrix.

## Ground rules

- Docs first: behavior is specified in [Docs/PERMISSION_MATRIX.md](Docs/PERMISSION_MATRIX.md) before an adapter is implemented
- Public API changes require an architecture decision record in [Docs/Decisions](Docs/Decisions)
- Swift 6 language mode with strict concurrency; no `@unchecked Sendable`
- No external runtime dependencies
- Code style is enforced by the toolchain's `swift format` using the repository's `.swift-format` configuration; run `swift format --in-place --recursive Sources Tests Package.swift` before pushing
- Denial and restriction are values, not errors
- Reading status must never trigger a system prompt
- The library never opens Settings or requests permission automatically

## Adding or changing a capability

1. Complete or update its section in the permission matrix
2. Record public API changes as an ADR
3. Implement the adapter behind the injectable native shim
4. Add mapping tests for every native state, including unknown future values
5. Add contract and coordination tests against a scripted shim
6. Add a demo app screen and manual checklist entries
7. Verify on a physical device and document the results

## Git workflow

The process is intentionally small:

1. Branch from `main`: `feature/<name>`, `fix/<name>`, or `docs/<name>`
2. Open a pull request; CI must pass
3. Squash merge; delete the branch
4. `main` is always releasable: green build and tests at every commit

There are no long-lived branches. Releases are semantic-version tags on
`main`; before 1.0, minor versions may contain breaking changes.

Commit messages use the imperative mood ("Add camera adapter") with a body
when the change needs explanation.

## Pull requests

- Keep changes focused; one capability or concern per pull request
- All CI checks must pass, including strict concurrency
- Update documentation in the same pull request as behavior changes

## Reporting issues

For behavior differences on specific devices or OS versions, include the iOS version, device model, and the exact permission state transitions observed.
