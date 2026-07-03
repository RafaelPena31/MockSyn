# Test Integration

Block 10 connects MockSyn runtime failures to test frameworks without adding a
hard XCTest or Swift Testing dependency to the runtime target.

## What It Does

| Feature | Status | Notes |
| --- | --- | --- |
| XCTest adapter | Supported | `MockSynFailureReporter.useXCTest` accepts an XCTest-style failure closure. |
| Swift Testing adapter | Supported | `MockSynFailureReporter.useSwiftTesting` accepts a Swift Testing-style issue closure. |
| Custom reporter | Supported | `setHandler` accepts a `MockSynFailure` handler. |
| File/line forwarding | Supported | Verification APIs forward `file` and `line` into reported failures. |
| Detailed messages | Supported | Verification reports include recorded calls when available. |

## XCTest

Configure the reporter from the test target:

```swift
import MockSyn
import XCTest

final class UserServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()

        MockSynFailureReporter.useXCTest { message, file, line in
            XCTFail(message, file: file, line: line)
        }
    }

    override func tearDown() {
        MockSynFailureReporter.reset()
        super.tearDown()
    }
}
```

The closure shape keeps `MockSyn` free of an XCTest dependency in production
targets.

## Swift Testing

Configure a Swift Testing-style recorder from tests:

```swift
MockSynFailureReporter.useSwiftTesting { message, file, line in
    let filePath = "\(file)"

    Issue.record(Comment(rawValue: message), sourceLocation: SourceLocation(
        fileID: filePath,
        filePath: filePath,
        line: Int(line),
        column: 1
    ))
}
```

Exact `Issue.record` overloads can vary by toolchain, so MockSyn exposes a small
adapter closure and lets the test target bind it to the available Swift Testing
API.

## Custom Reporter

```swift
MockSynFailureReporter.setHandler { failure in
    print("\(failure.file):\(failure.line): \(failure.message)")
}
```

`MockSynFailure` carries:

- `message`;
- `file`;
- `line`.

## File And Line Forwarding

Verification APIs forward source metadata:

```swift
try service.verify.load(id: .value("42")).once()
try service.verify.refresh().times(2)
try MockSynVerifier.verifyOrder(first.verify.refresh(), second.verify.refresh())
```

The default arguments point to the test call site. Advanced users can override
them:

```swift
try service.verify.load(id: .value("42")).once(file: "CustomFile.swift", line: 10)
```

## Detailed Messages

Verification failures include the expected condition and recorded calls:

```text
Expected save(_:) to be called exactly 1 time, but it was called 0 times
Recorded calls:
- save(_:)(received)
```

This makes the reporter output useful even before framework-specific formatting
is applied.

## Current Limits

- MockSyn exposes adapter closures instead of importing XCTest or Swift Testing
  from the runtime module.
- Generated non-throwing calls that fail through `try!` still crash after the
  runtime reports the failure.
- Rich argument rendering beyond `String(describing:)` is planned for diagnostics.
