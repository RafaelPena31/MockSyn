/// Type-safe argument matcher used by generated stubbing APIs.
public struct MockSynMatcher<Value> {
    private let matcher: (Value) -> Bool

    private init(matcher: @escaping (Value) -> Bool) {
        self.matcher = matcher
    }

    /// Matches any value.
    public static var any: MockSynMatcher<Value> {
        MockSynMatcher { _ in true }
    }

    /// Matches a value using `Equatable`.
    public static func value(_ expected: Value) -> MockSynMatcher<Value> where Value: Equatable {
        MockSynMatcher { actual in
            actual == expected
        }
    }

    /// Matches a value using a custom predicate.
    public static func matching(_ predicate: @escaping (Value) -> Bool) -> MockSynMatcher<Value> {
        MockSynMatcher(matcher: predicate)
    }

    /// Erases the matcher type for storage inside MockSyn runtime state.
    public func erase() -> MockSynAnyMatcher {
        MockSynAnyMatcher { value in
            guard let typedValue = value as? Value else {
                return false
            }

            return matcher(typedValue)
        }
    }
}

/// Type-erased argument matcher stored by the runtime.
public struct MockSynAnyMatcher {
    private let matcher: (Any) -> Bool

    init(matcher: @escaping (Any) -> Bool) {
        self.matcher = matcher
    }

    func matches(_ value: Any) -> Bool {
        matcher(value)
    }
}
