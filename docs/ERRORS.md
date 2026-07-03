# Errors

MockSyn has two kinds of errors: compile-time diagnostics from macros and runtime test failures from generated mocks.

## Principles

- Fail early when a declaration cannot be generated correctly.
- Prefer clear diagnostics over confusing type-checker errors.
- Runtime failures should identify the mock, member, expected behavior, received arguments, and file/line.
- Errors must include a recovery suggestion when one exists.

## Compile-Time Diagnostics

| Case | Diagnostic behavior |
| --- | --- |
| Macro on unsupported declaration | Emit an error explaining valid targets. |
| Pure Swift final class | Emit an error recommending protocol extraction. |
| Private member requirement | Emit an error because generated code cannot satisfy inaccessible requirements. |
| Unsupported operator | Emit an error or warning depending on planned support. |
| Unsupported protocol inheritance | Emit an error explaining the supported inheritance model. |
| Invalid access override | Emit an error when requested access is wider than allowed. |
| Unsupported generic shape | Emit an error describing the unsupported generic construct. |

Example:

```text
MockSyn cannot generate UserServiceMock because UserService is a final class. Extract a protocol and apply @Mocking to the protocol.
```

## Runtime Failures

| Case | Failure |
| --- | --- |
| Missing stub in strict mode | The call fails and reports the missing member and arguments. |
| Missing default in relaxed mode | The call fails with a message asking for a stub or default value. |
| Verify expected call not found | Reports expected call, expected count, actual matching count, and all received calls for that member. |
| Extra calls after `confirmVerified` | Reports unverified calls. |
| Unused stubs | Reports configured stubs that were never consumed. |
| Timeout verification | Reports expected call and timeout duration. |
| Matcher type mismatch | Reports expected matcher type and actual argument type. |

## Failure Reporter

MockSyn uses a pluggable reporter:

```swift
MockSynFailureReporter.useXCTest { message, file, line in
    XCTFail(message, file: file, line: line)
}
```

Adapters:

- XCTest-style adapter through `MockSynFailureReporter.useXCTest`.
- Swift Testing-style adapter through `MockSynFailureReporter.useSwiftTesting`.
- Custom reporter for advanced users.

## File And Line

Public verification APIs should accept `fileID`, `filePath`, `line`, and `column` defaults when supported by the language/toolchain. Failures should point to the test line, not to generated code.

## Error Message Format

Runtime failures should follow this shape:

```text
MockSyn verify failed
Mock: UserServiceMock
Member: fetchUser(id:)
Expected: called once with id == "123"
Actual: called 0 times
Recorded calls:
- fetchUser(id: "456")
Suggestion: check the argument matcher or call path under test.
```
