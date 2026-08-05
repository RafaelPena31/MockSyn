/// Rethrowing builder for members with three arguments.
public struct MockSynRethrowingStubBuilder3<First, Second, Third, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated `rethrows` builder for three argument matchers.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 3, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    /// Runs a non-throwing closure with the three received arguments.
    public func willRun(_ body: @escaping (First, Second, Third) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self)
            )
        })
    }
}

/// Rethrowing builder for members with four arguments.
public struct MockSynRethrowingStubBuilder4<First, Second, Third, Fourth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated `rethrows` builder for four argument matchers.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 4, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    /// Runs a non-throwing closure with the four received arguments.
    public func willRun(_ body: @escaping (First, Second, Third, Fourth) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 3, as: Fourth.self, builder: Self.self)
            )
        })
    }
}

/// Rethrowing builder for members with five arguments.
public struct MockSynRethrowingStubBuilder5<First, Second, Third, Fourth, Fifth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated `rethrows` builder for five argument matchers.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 5, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    /// Runs a non-throwing closure with the five received arguments.
    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 2, as: Third.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 3, as: Fourth.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 4, as: Fifth.self, builder: Self.self)
            )
        })
    }
}

/// Rethrowing builder for members with six arguments.
public struct MockSynRethrowingStubBuilder6<First, Second, Third, Fourth, Fifth, Sixth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated `rethrows` builder for six argument matchers.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 6, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    /// Runs a non-throwing closure with the six received arguments.
    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth, Sixth) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
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

/// Return-only builder used when typed `willRun` is unavailable for a rethrows member.
public struct MockSynRethrowingStubBuilderReturnOnly<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates a builder for a `rethrows` member without a typed closure overload.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }
}
