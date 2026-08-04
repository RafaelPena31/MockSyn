/// Throwing-capable builder for members with three arguments.
public struct MockSynStubBuilder3<First, Second, Third, Return> {
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

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(arguments[0] as! First, arguments[1] as! Second, arguments[2] as! Third)
        })
    }
}

/// Throwing-capable builder for members with four arguments.
public struct MockSynStubBuilder4<First, Second, Third, Fourth, Return> {
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

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
                arguments[0] as! First,
                arguments[1] as! Second,
                arguments[2] as! Third,
                arguments[3] as! Fourth
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
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
                arguments[0] as! First,
                arguments[1] as! Second,
                arguments[2] as! Third,
                arguments[3] as! Fourth,
                arguments[4] as! Fifth
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
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    public func willRun(_ body: @escaping (First, Second, Third, Fourth, Fifth, Sixth) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(
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

    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }
}
