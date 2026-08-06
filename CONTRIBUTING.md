# Contributing to Permissionary

Thanks for helping improve Permissionary.

Permissionary is a public Swift package with an evolving pre-1.0 API. Bug reports,
documentation improvements, tests, device-specific findings, and focused code changes are
welcome.

## Before you start

- Search the existing issues before opening a new one.
- Small fixes can go directly to a pull request.
- For a new capability or a substantial public API change, open an issue first so the behavior
  and native framework semantics can be agreed on before implementation.

## Development setup

1. Clone the repository and open `Package.swift` in Xcode.
2. Select the `Permissionary` scheme and an available iOS Simulator.
3. Run the test suite with **Product → Test**.
4. Open `Examples/PermissionaryDemo/PermissionaryDemo.xcodeproj` to exercise permission flows in
   the demo app. Native prompts and Settings recovery should also be verified on a physical
   device when relevant.

Before opening a pull request, format and lint the repository:

```sh
swift format --in-place --recursive Sources Tests Examples Package.swift
swift format lint --strict --recursive Sources Tests Examples Package.swift
```

CI runs the strict formatting check, package tests on an iOS Simulator, a demo-app build, and a
DocC build with warnings treated as errors.

## Ground rules

- Specify behavior in [Docs/PERMISSION_MATRIX.md](Docs/PERMISSION_MATRIX.md) before adding or
  changing a capability.
- Update the API and architecture documentation with public API changes.
- Use Swift 6 strict concurrency without `@unchecked Sendable`.
- Do not add external runtime dependencies.
- Treat denial and restriction as values, not errors.
- Reading status must never trigger a system prompt.
- The library must never open Settings or request permission automatically.

## Adding or changing a capability

1. Complete or update its section in the permission matrix.
2. Update the API and architecture documentation for public changes.
3. Implement the adapter behind the injectable native shim.
4. Add mapping tests for every native state, including unknown future values.
5. Add contract and coordination tests against a scripted shim.
6. Add or update the corresponding demo-app screen.
7. Verify the affected flows on a physical device and describe the results in the pull request.

## Git workflow

1. Branch from `main` using `feature/<name>`, `fix/<name>`, or `docs/<name>`.
2. Make focused commits using the imperative mood, such as `Add camera status test`.
3. Open a pull request describing the behavior change and how it was verified.
4. Address review feedback and keep every CI check green.

There are no long-lived branches. Pull requests are squash-merged, and `main` remains releasable
at every commit. Releases are semantic-version tags; before 1.0, minor versions may contain
breaking changes.

## Pull requests

- Keep each pull request focused on one coherent change.
- Include tests for behavior changes and regressions.
- Update documentation and the demo app when their behavior or examples change.
- Describe manual device testing when the change affects a native permission prompt, Settings
  recovery, or a framework-specific limited-access flow.
- All CI checks must pass before merge.

## Reporting issues

For a permission-state or recovery problem, include:

- iOS version and device model, or the Simulator configuration
- Permission capability and initial state
- Exact sequence of prompts, Settings changes, and app lifecycle events
- Expected and observed results
- A minimal reproduction or sample code when possible

Do not include secrets, provisioning profiles, or sensitive application data.
