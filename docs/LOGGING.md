# Logging

MockSyn should not log during normal test execution. Logs are only for diagnostic mode and must have no meaningful overhead when disabled.

## Principles

- No logs by default.
- No string formatting for disabled logs.
- No log-based behavior.
- Diagnostics must not hide test failures.
- Logs are for framework debugging, not user assertions.

## Diagnostic Mode

Diagnostic logging is enabled explicitly:

```swift
MockSynDiagnostics.enableLogging()
```

or through a compile-time flag:

```swift
MOCKSYN_DIAGNOSTICS
```

## Categories

| Category | Use |
| --- | --- |
| `macro` | Macro expansion summaries and skipped members in development builds of MockSyn. |
| `runtime` | Invocation and stub registry diagnostics. |
| `verification` | Verification matching details. |
| `performance` | Benchmark-only timing events. |

## Technology

Use `os.Logger` on Apple platforms. Keep the logging wrapper internal so the public API is not tied to a specific logging backend.

## Sensitive Data

MockSyn should avoid logging argument values by default. If diagnostic logs include arguments, this must be explicitly enabled because test data can contain tokens, emails, or personal data.
