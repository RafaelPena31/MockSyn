/// Rethrowing builder for members with three arguments.
public struct MockSynRethrowingStubBuilder3<First, Second, Third, Return> {
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

/// Rethrowing builder for members with four arguments.
public struct MockSynRethrowingStubBuilder4<First, Second, Third, Fourth, Return> {
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

/// Rethrowing builder for members with five arguments.
public struct MockSynRethrowingStubBuilder5<First, Second, Third, Fourth, Fifth, Return> {
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

/// Rethrowing builder for members with six arguments.
public struct MockSynRethrowingStubBuilder6<First, Second, Third, Fourth, Fifth, Sixth, Return> {
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

/// Return-only builder used when typed `willRun` is unavailable for a rethrows member.
public struct MockSynRethrowingStubBuilderReturnOnly<Return> {
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
