# Verification

Block 6 adds invocation recording and generated verification APIs for mocks,
stubs, and spies. Generated members record calls through `MockSynRuntime`, and
tests can assert call counts, arguments, order, and unused interactions.

## Basic Usage

```swift
@Mocking
protocol UserService {
    var displayName: String { get set }
    func load(id: String) -> String
    func refresh()
}

#if MOCKSYN_ENABLE
let service = UserServiceMock()

service.given.load(id: .any).willReturn("Rafael")

_ = service.load(id: "42")
service.refresh()
service.displayName = "Rafael"

try service.verify.load(id: .value("42")).once()
try service.verify.refresh().wasCalled(.once)
try service.verify.displayName.set(.value("Rafael")).times(1)
try service.confirmVerified()
#endif
```

## Count Verification

`MockSynVerification` supports these count rules:

| Rule | Meaning |
| --- | --- |
| `.once` / `once()` | Exactly one matching call. |
| `.never` / `never()` | No matching calls. |
| `.times(n)` / `times(n)` | Exactly `n` matching calls. |
| `.atLeast(n)` / `atLeast(n)` | At least `n` matching calls. |
| `.atMost(n)` / `atMost(n)` | At most `n` matching calls. |

```swift
try service.verify.refresh().atLeast(1)
try service.verify.load(id: .any).atMost(2)
```

## Argument Verification

Verification uses the same typed matchers as stubbing:

```swift
try service.verify.load(id: .value("42")).once()
try service.verify.load(id: .any).times(2)
try service.verify.load(id: .matching { $0.hasPrefix("user-") }).atLeast(1)
try service.verify.lookup(email: .notNil).once()
```

Argument captors can be used as verification matchers when the test needs to
inspect the value after matching the call:

```swift
let captor = MockSynArgumentCaptor<String>()

try service.verify.load(id: captor.capture()).once()

XCTAssertEqual(captor.value, "user-42")
```

## Properties And Subscripts

Properties expose `get` and `set` verification entries. Subscripts expose the
same shape after selecting the index matchers.

```swift
try service.verify.displayName.get.never()
try service.verify.displayName.set(.value("Rafael")).once()

try service.verify.`subscript`(key: .value("theme")).get.once()
try service.verify.`subscript`(key: .any).set(.value("dark")).times(1)
```

## Order Verification

`MockSynVerifier.verifyOrder` checks the first matching invocation for each
verification query. The queries can belong to different generated doubles.

```swift
let first = UserServiceMock()
let second = UserServiceMock()

first.refresh()
second.refresh()

try MockSynVerifier.verifyOrder(
    first.verify.refresh(),
    second.verify.refresh()
)
```

## Confirming Verification

`confirmVerified()` fails if any recorded invocation on that generated double was
not verified.

```swift
service.refresh()

try service.verify.refresh().once()
try service.confirmVerified()
```

## Unused Stubs

`checkUnnecessaryStubs()` fails when a configured stub was never matched by a
call. This helps keep tests small and prevents stale expectations.

```swift
service.given.load(id: .value("used")).willReturn("ok")
service.given.load(id: .value("unused")).willReturn("stale")

_ = service.load(id: "used")

try service.checkUnnecessaryStubs() // Fails because "unused" was never used.
```

## Timeout Verification

Async tests can wait for a call to arrive within a timeout.

```swift
Task {
    service.refresh()
}

try await service.verify.refresh().wasCalled(.once, timeout: 0.5)
```

## Failure Details

Count mismatches throw `MockSynVerificationError.expected` with the expected
count, actual count, and rendered calls recorded for that member:

```text
Expected load(id:) to be called exactly 1 time, but it was called 0 times
Recorded calls:
- load(id:)("received")
```

The same description is sent to the configured failure reporter. The
`recordedCalls` associated value was added to the public error case; code that
pattern-matches the case must accept all four values.

## Static Verification And Cleanup

Static member verification is available on the generated type, for example
`try IDFactoryMock.verify.make(id: .value("primary")).once()`. Use
`MockSynRuntime.resetAllGlobalState()` at a sequential suite boundary to clear
all registered static runtimes together with defaults, reporter configuration,
and call-order state.
