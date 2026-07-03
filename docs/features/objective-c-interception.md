# Objective-C Interception

`MockSynObjCInterception` provides scoped Objective-C method replacement for
tests that need to intercept selectors visible to `ObjectiveC.runtime`.

This is not macro-generated mocking. It is an explicit runtime API for the small
set of cases where Objective-C dispatch is actually available.

## When To Use

Use this API when:

- the type or member is visible to the Objective-C runtime;
- the member has a stable `Selector`;
- subclass-based doubles are not enough for the test;
- the test can keep a restoration token alive for the interception scope.

Do not use it for:

- pure Swift methods;
- pure Swift final dispatch;
- global functions;
- arbitrary constructors;
- static Swift calls that are not Objective-C class methods.

## Instance Methods

```swift
final class LegacyService: NSObject {
    @objc dynamic func greeting() -> NSString {
        "real"
    }
}

let replacement: @convention(block) (AnyObject) -> NSString = { _ in
    "mock"
}

let interception = try MockSynObjCInterception.replaceInstanceMethod(
    on: LegacyService.self,
    selector: #selector(LegacyService.greeting),
    with: replacement
)

XCTAssertEqual(LegacyService().greeting(), "mock")

interception.restore()

XCTAssertEqual(LegacyService().greeting(), "real")
```

## Class Methods

```swift
final class LegacyFactory: NSObject {
    @objc dynamic class func makeName() -> NSString {
        "real"
    }
}

let replacement: @convention(block) (AnyClass) -> NSString = { _ in
    "mock"
}

let interception = try MockSynObjCInterception.replaceClassMethod(
    on: LegacyFactory.self,
    selector: #selector(LegacyFactory.makeName),
    with: replacement
)

XCTAssertEqual(LegacyFactory.makeName(), "mock")
interception.restore()
```

## Restoration

The returned token owns the installed implementation. MockSyn restores the
original implementation when:

- `restore()` is called;
- the token is released.

`restore()` is idempotent.

## Errors

MockSyn throws `MockSynObjCInterceptionError` when the selector cannot be found:

```text
MockSyn could not find Objective-C instance method missingSelector on LegacyService.
```

or:

```text
MockSyn could not find Objective-C class method missingSelector on LegacyService.
```

## Performance

The interception changes a method implementation once per installed token. It
does not participate in macro expansion and does not add build-time work. Keep
interception scopes narrow because swizzling changes dispatch for the affected
Objective-C method globally while the token is alive.
