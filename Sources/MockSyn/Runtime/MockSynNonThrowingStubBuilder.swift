/// Builder for non-throwing members without arguments.
public struct MockSynNonThrowingStubBuilder<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]
    private let notifyChangeOnRegistration: Bool

    /// Creates a builder for a generated member without arguments.
    public init(
        runtime: MockSynRuntime,
        member: String,
        matchers: [MockSynAnyMatcher] = [],
        notifyChangeOnRegistration: Bool = false
    ) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
        self.notifyChangeOnRegistration = notifyChangeOnRegistration
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(
            member: member,
            matchers: matchers,
            behavior: .returns(first: first, remaining: remaining),
            notifyChange: notifyChangeOnRegistration
        )
    }

    /// Runs the configured non-throwing closure.
    public func willRun(_ body: @escaping () -> Return) {
        runtime.registerStub(
            member: member,
            matchers: matchers,
            behavior: .runsNonThrowing { _ in body() },
            notifyChange: notifyChangeOnRegistration
        )
    }
}

/// Builder for non-throwing members with one argument.
public struct MockSynNonThrowingStubBuilder1<Argument, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated builder for one argument matcher.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 1, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    /// Runs a typed closure with the received argument.
    public func willRun(_ body: @escaping (Argument) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(mockSynTypedArgument(arguments, at: 0, as: Argument.self, builder: Self.self))
        })
    }
}

/// Builder for non-throwing members with two arguments.
public struct MockSynNonThrowingStubBuilder2<First, Second, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated builder for two argument matchers.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        mockSynValidateMatcherCount(builder: Self.self, expected: 2, actual: matchers.count)
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Returns the configured values in sequence, repeating the last value.
    public func willReturn(_ first: Return, _ remaining: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(first: first, remaining: remaining))
    }

    /// Runs a typed closure with the two received arguments.
    public func willRun(_ body: @escaping (First, Second) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                mockSynTypedArgument(arguments, at: 0, as: First.self, builder: Self.self),
                mockSynTypedArgument(arguments, at: 1, as: Second.self, builder: Self.self)
            )
        })
    }
}

/// Builder for non-throwing members with three arguments.
public struct MockSynNonThrowingStubBuilder3<First, Second, Third, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated builder for three argument matchers.
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

    /// Runs a typed closure with the three received arguments.
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

/// Builder for non-throwing members with four arguments.
public struct MockSynNonThrowingStubBuilder4<First, Second, Third, Fourth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated builder for four argument matchers.
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

    /// Runs a typed closure with the four received arguments.
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

/// Builder for non-throwing members with five arguments.
public struct MockSynNonThrowingStubBuilder5<First, Second, Third, Fourth, Fifth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated builder for five argument matchers.
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

    /// Runs a typed closure with the five received arguments.
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

/// Builder for non-throwing members with six arguments.
public struct MockSynNonThrowingStubBuilder6<First, Second, Third, Fourth, Fifth, Sixth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates the generated builder for six argument matchers.
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

    /// Runs a typed closure with the six received arguments.
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

/// Return-only builder used when typed `willRun` is unavailable.
public struct MockSynNonThrowingStubBuilderReturnOnly<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates a builder for a member whose arity has no typed closure overload.
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

/// Generated property stubbing entrypoint for non-throwing accessors.
public struct MockSynNonThrowingPropertyStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String

    /// Creates a stubbing entrypoint for a readable and writable property.
    public init(runtime: MockSynRuntime, getMember: String, setMember: String) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
    }

    /// Builder for property getter behavior.
    public var get: MockSynNonThrowingStubBuilder<Value> {
        MockSynNonThrowingStubBuilder(runtime: runtime, member: getMember, notifyChangeOnRegistration: true)
    }

    /// Builder for assignments matching the supplied value matcher.
    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynNonThrowingStubBuilder1<Value, Void> {
        MockSynNonThrowingStubBuilder1(runtime: runtime, member: setMember, matchers: [matcher.erase()])
    }
}

/// Generated property stubbing entrypoint for read-only non-throwing accessors.
public struct MockSynNonThrowingReadOnlyPropertyStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String

    /// Creates a stubbing entrypoint for a read-only property.
    public init(runtime: MockSynRuntime, getMember: String) {
        self.runtime = runtime
        self.getMember = getMember
    }

    /// Builder for property getter behavior.
    public var get: MockSynNonThrowingStubBuilder<Value> {
        MockSynNonThrowingStubBuilder(runtime: runtime, member: getMember, notifyChangeOnRegistration: true)
    }
}

/// Generated subscript stubbing entrypoint for non-throwing accessors.
public struct MockSynNonThrowingSubscriptStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String
    private let indexMatchers: [MockSynAnyMatcher]

    /// Creates a stubbing entrypoint for a readable and writable subscript.
    public init(runtime: MockSynRuntime, getMember: String, setMember: String, indexMatchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
        self.indexMatchers = indexMatchers
    }

    /// Builder for subscript getter behavior.
    public var get: MockSynNonThrowingStubBuilder<Value> {
        MockSynNonThrowingStubBuilder(runtime: runtime, member: getMember, matchers: indexMatchers)
    }

    /// Builder for assignments matching the supplied value matcher.
    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynNonThrowingSubscriptSetterStubBuilder<Value> {
        MockSynNonThrowingSubscriptSetterStubBuilder(
            runtime: runtime,
            member: setMember,
            matchers: indexMatchers + [matcher.erase()]
        )
    }
}

/// Generated subscript stubbing entrypoint for read-only non-throwing accessors.
public struct MockSynNonThrowingReadOnlySubscriptStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let indexMatchers: [MockSynAnyMatcher]

    /// Creates a stubbing entrypoint for a read-only subscript.
    public init(runtime: MockSynRuntime, getMember: String, indexMatchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.getMember = getMember
        self.indexMatchers = indexMatchers
    }

    /// Builder for subscript getter behavior.
    public var get: MockSynNonThrowingStubBuilder<Value> {
        MockSynNonThrowingStubBuilder(runtime: runtime, member: getMember, matchers: indexMatchers)
    }
}

/// Non-throwing builder for generated subscript setters.
public struct MockSynNonThrowingSubscriptSetterStubBuilder<Value> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    /// Creates a builder for a generated subscript setter.
    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Runs a closure with the assigned value after all matchers succeed.
    public func willRun(_ body: @escaping (Value) -> Void) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(mockSynLastTypedArgument(arguments, as: Value.self, builder: Self.self))
        })
    }
}
