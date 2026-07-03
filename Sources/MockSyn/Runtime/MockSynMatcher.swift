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

    /// Matches optional values that are `nil`.
    public static var `nil`: MockSynMatcher<Value> {
        MockSynMatcher { value in
            Mirror(reflecting: value).displayStyle == .optional && Mirror(reflecting: value).children.isEmpty
        }
    }

    /// Matches optional values that are not `nil`.
    public static var notNil: MockSynMatcher<Value> {
        MockSynMatcher { value in
            Mirror(reflecting: value).displayStyle == .optional && !Mirror(reflecting: value).children.isEmpty
        }
    }

    /// Inverts this matcher.
    public var not: MockSynMatcher<Value> {
        MockSynMatcher { value in
            !matcher(value)
        }
    }

    /// Matches only when all provided matchers match.
    public static func all(_ matchers: MockSynMatcher<Value>...) -> MockSynMatcher<Value> {
        MockSynMatcher { value in
            matchers.allSatisfy { $0.matcher(value) }
        }
    }

    /// Matches when at least one provided matcher matches.
    public static func anyOf(_ matchers: MockSynMatcher<Value>...) -> MockSynMatcher<Value> {
        MockSynMatcher { value in
            matchers.contains { $0.matcher(value) }
        }
    }

    /// Matches arrays that contain the expected element.
    public static func contains<Element>(_ expected: Element) -> MockSynMatcher<Value>
    where Value == [Element], Element: Equatable {
        MockSynMatcher { value in
            value.contains(expected)
        }
    }

    /// Matches sets that contain the expected element.
    public static func contains<Element>(_ expected: Element) -> MockSynMatcher<Value>
    where Value == Set<Element> {
        MockSynMatcher { value in
            value.contains(expected)
        }
    }

    /// Matches dictionaries that contain the expected key.
    public static func contains<Key, DictionaryValue>(key: Key) -> MockSynMatcher<Value>
    where Value == [Key: DictionaryValue] {
        MockSynMatcher { value in
            value[key] != nil
        }
    }

    /// Matches dictionaries that contain the expected key/value pair.
    public static func contains<Key, DictionaryValue>(key: Key, value expectedValue: DictionaryValue) -> MockSynMatcher<Value>
    where Value == [Key: DictionaryValue], DictionaryValue: Equatable {
        MockSynMatcher { value in
            value[key] == expectedValue
        }
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

public extension MockSynMatcher where Value: Collection {
    /// Matches empty collections.
    static var isEmpty: MockSynMatcher<Value> {
        MockSynMatcher { value in
            value.isEmpty
        }
    }
}

/// Type-erased argument matcher stored by the runtime.
public struct MockSynAnyMatcher {
    private let matcher: (Any) -> Bool

    init(matcher: @escaping (Any) -> Bool) {
        self.matcher = matcher
    }

    /// Evaluates the erased matcher against a boxed value.
    public func matches(_ value: Any) -> Bool {
        matcher(value)
    }
}
