/// Throwing-capable builder for members with three arguments.
public struct MockSynStubBuilder3<First, Second, Third, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 3, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self)
            )
        })
    }
}

/// Throwing-capable builder for members with four arguments.
public struct MockSynStubBuilder4<First, Second, Third, Fourth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 4, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 3, as: Fourth.self, builder: Self.self)
            )
        })
    }
}

/// Throwing-capable builder for members with five arguments.
public struct MockSynStubBuilder5<First, Second, Third, Fourth, Fifth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 5, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 3, as: Fourth.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 4, as: Fifth.self, builder: Self.self)
            )
        })
    }
}

/// Throwing-capable builder for members with six arguments.
public struct MockSynStubBuilder6<First, Second, Third, Fourth, Fifth, Sixth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 6, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth, Sixth) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 3, as: Fourth.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 4, as: Fifth.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 5, as: Sixth.self, builder: Self.self)
            )
        })
    }
}

/// Throwing-capable return-only builder used when typed `willRun` is unavailable.
public struct MockSynStubBuilderReturnOnly<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }
}
