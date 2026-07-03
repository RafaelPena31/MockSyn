# Matchers And Captors

Block 7 adds richer typed matchers and captors. They work with the generated
`given`, `when`, and `verify` APIs because those APIs already accept
`MockSynMatcher<Value>` for each argument.

## What It Does

| Feature | Status | Notes |
| --- | --- | --- |
| `.any` | Supported | Matches any value of the expected argument type. |
| `.value(x)` | Supported | Matches an `Equatable` value. |
| `.matching { }` | Supported | Matches with a custom predicate. |
| `.nil` / `.notNil` | Supported | Matches optional arguments by nil state. |
| Collection matchers | Supported | Includes `isEmpty`, array `contains`, set `contains`, dictionary key, and dictionary key/value matchers. |
| Composed matchers | Supported | Includes `.not`, `.all`, and `.anyOf`. |
| Argument captor | Supported | Captures typed arguments during matching. |
| Closure captor | Supported | Captures closure arguments using the same captor implementation. |

## When To Use

Use matchers when a test should not hard-code every argument value. Use captors
when the test needs to inspect an argument after the call has happened, or when
the test needs to invoke a captured completion closure.

Prefer `.value` for exact values, `.matching` for domain rules, collection
matchers for common container assertions, and captors when assertions are clearer
after the call.

## Basic Matchers

```swift
service.given.load(id: .any).willReturn(user)
service.given.load(id: .value("42")).willReturn(admin)
service.given.load(id: .matching { $0.hasPrefix("user-") }).willReturn(user)
```

## Optional Matchers

```swift
service.given.lookup(email: .nil).willReturn(nil)
service.given.lookup(email: .notNil).willReturn(profile)

try service.verify.lookup(email: .notNil).once()
```

The optional matcher is intentionally type-safe at the generated API boundary:
the method argument still determines the `MockSynMatcher<Value>` type.

## Collection Matchers

```swift
service.given.sync(ids: .isEmpty).willReturn([])
service.given.sync(ids: .contains("42")).willReturn([user])
service.given.authorize(roles: .contains("admin")).willReturn(true)
service.given.configure(values: .contains(key: "timeout")).willReturn(config)
service.given.configure(values: .contains(key: "mode", value: "test")).willReturn(config)
```

`isEmpty` works for any `Collection`. `contains` has overloads for arrays, sets,
and dictionaries.

## Composed Matchers

```swift
let positive = MockSynMatcher<Int>.matching { $0 > 0 }
let even = MockSynMatcher<Int>.matching { $0.isMultiple(of: 2) }

service.given.score(.all(positive, even)).willReturn("valid")
service.given.score(.anyOf(.value(1), .value(2))).willReturn("small")
service.given.score(.value(0).not).willReturn("non-zero")
```

Use composed matchers to keep setup readable when more than one rule matters.

## Argument Captor

```swift
let captor = MockSynArgumentCaptor<String>()

_ = service.load(id: "user-42")

try service.verify.load(id: captor.capture()).once()

XCTAssertEqual(captor.value, "user-42")
XCTAssertEqual(captor.values, ["user-42"])
```

Captors capture in call order. `value` returns the most recent captured value and
is `nil` until a matching value has been captured.

Captors can also be used during stubbing:

```swift
let captor = MockSynArgumentCaptor<Int>()

service.given.doubled(captor.capture()).willRun { value in
    value * 2
}

XCTAssertEqual(service.doubled(4), 8)
XCTAssertEqual(captor.value, 4)
```

## Closure Captor

```swift
let completion = MockSynClosureCaptor<(String) -> Void>()

service.handle { value in
    received = value
}

try service.verify.handle(completion.capture()).once()
completion.value?("done")

XCTAssertEqual(received, "done")
```

Closure captors are useful for completion-handler APIs where the test should
control when the captured callback is executed.

## Current Limits

- Captors capture whenever their matcher is evaluated. Avoid reusing the same
  captor across unrelated verifications unless repeated captures are intended.
- Static member stubbing and verification use the same matchers on type-level
  `given` and `verify` APIs.
- Testing-framework adapters are not implemented yet; verification currently
  throws `MockSynVerificationError`.
