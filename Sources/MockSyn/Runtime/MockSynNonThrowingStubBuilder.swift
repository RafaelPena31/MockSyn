/// Builder for non-throwing members without arguments.
public struct MockSynNonThrowingStubBuilder<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher] = []) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping () -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { _ in body() })
    }
}

/// Builder for non-throwing members with one argument.
public struct MockSynNonThrowingStubBuilder1<Argument, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping (Argument) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(arguments[0] as! Argument)
        })
    }
}

/// Builder for non-throwing members with two arguments.
public struct MockSynNonThrowingStubBuilder2<First, Second, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping (First, Second) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(arguments[0] as! First, arguments[1] as! Second)
        })
    }
}

/// Builder for non-throwing members with three arguments.
public struct MockSynNonThrowingStubBuilder3<First, Second, Third, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping (First, Second, Third) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(arguments[0] as! First, arguments[1] as! Second, arguments[2] as! Third)
        })
    }
}

/// Builder for non-throwing members with four arguments.
public struct MockSynNonThrowingStubBuilder4<First, Second, Third, Fourth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                arguments[0] as! First,
                arguments[1] as! Second,
                arguments[2] as! Third,
                arguments[3] as! Fourth
            )
        })
    }
}

/// Builder for non-throwing members with five arguments.
public struct MockSynNonThrowingStubBuilder5<First, Second, Third, Fourth, Fifth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                arguments[0] as! First,
                arguments[1] as! Second,
                arguments[2] as! Third,
                arguments[3] as! Fourth,
                arguments[4] as! Fifth
            )
        })
    }
}

/// Builder for non-throwing members with six arguments.
public struct MockSynNonThrowingStubBuilder6<First, Second, Third, Fourth, Fifth, Sixth, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth, Sixth) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(
                arguments[0] as! First,
                arguments[1] as! Second,
                arguments[2] as! Third,
                arguments[3] as! Fourth,
                arguments[4] as! Fifth,
                arguments[5] as! Sixth
            )
        })
    }
}

/// Return-only builder used when typed `willRun` is unavailable.
public struct MockSynNonThrowingStubBuilderReturnOnly<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }
}

/// Generated property stubbing entrypoint for non-throwing accessors.
public struct MockSynNonThrowingPropertyStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String

    public init(runtime: MockSynRuntime, getMember: String, setMember: String) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
    }

    public var get: MockSynNonThrowingStubBuilder<Value> {
        MockSynNonThrowingStubBuilder(runtime: runtime, member: getMember)
    }

    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynNonThrowingStubBuilder1<Value, Void> {
        MockSynNonThrowingStubBuilder1(runtime: runtime, member: setMember, matchers: [matcher.erase()])
    }
}

/// Generated subscript stubbing entrypoint for non-throwing accessors.
public struct MockSynNonThrowingSubscriptStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String
    private let indexMatchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, getMember: String, setMember: String, indexMatchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
        self.indexMatchers = indexMatchers
    }

    public var get: MockSynNonThrowingStubBuilder<Value> {
        MockSynNonThrowingStubBuilder(runtime: runtime, member: getMember, matchers: indexMatchers)
    }

    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynNonThrowingSubscriptSetterStubBuilder<Value> {
        MockSynNonThrowingSubscriptSetterStubBuilder(
            runtime: runtime,
            member: setMember,
            matchers: indexMatchers + [matcher.erase()]
        )
    }
}

/// Non-throwing builder for generated subscript setters.
public struct MockSynNonThrowingSubscriptSetterStubBuilder<Value> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willRun(_ body: @escaping (Value) -> Void) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(arguments[arguments.count - 1] as! Value)
        })
    }
}
