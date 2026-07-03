final class MockSynStubRule: @unchecked Sendable {
    private let matchers: [MockSynAnyMatcher]
    private var behavior: MockSynErasedStubBehavior
    private(set) var wasUsed = false

    init(matchers: [MockSynAnyMatcher], behavior: MockSynErasedStubBehavior) {
        self.matchers = matchers
        self.behavior = behavior
    }

    func matches(_ arguments: [Any]) -> Bool {
        MockSynRuntime.arguments(arguments, match: matchers)
    }

    func resolve(_ arguments: [Any]) throws -> Any {
        wasUsed = true
        return try behavior.resolve(arguments)
    }
}
