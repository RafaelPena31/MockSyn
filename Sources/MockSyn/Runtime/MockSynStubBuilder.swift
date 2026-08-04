/// Builder returned by generated `given` APIs for members without arguments.
public struct MockSynStubBuilder<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher] = []) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures one or more return values. Multiple values are returned sequentially.
    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    /// Configures the member to throw an error.
    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    /// Configures the member to run a custom closure.
    public func willRun(_ body: @escaping () throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { _ in
            try body()
        })
    }
}

/// Builder returned by generated `given` APIs for members with one argument.
public struct MockSynStubBuilder1<Argument, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures one or more return values. Multiple values are returned sequentially.
    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    /// Configures the member to throw an error.
    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    /// Configures the member to run a custom closure receiving the call argument.
    public func willRun(_ body: @escaping (Argument) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(arguments[0] as! Argument)
        })
    }
}

/// Builder returned by generated `given` APIs for members with two arguments.
public struct MockSynStubBuilder2<FirstArgument, SecondArgument, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures one or more return values. Multiple values are returned sequentially.
    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    /// Configures the member to throw an error.
    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Return>.throwing(error))
    }

    /// Configures the member to run a custom closure receiving both call arguments.
    public func willRun(_ body: @escaping (FirstArgument, SecondArgument) throws -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(arguments[0] as! FirstArgument, arguments[1] as! SecondArgument)
        })
    }
}

/// Builder returned by generated `given` APIs for `rethrows` members without arguments.
public struct MockSynRethrowingStubBuilder<Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher] = []) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures one or more return values. Multiple values are returned sequentially.
    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    /// Configures the member to run a custom non-throwing closure.
    public func willRun(_ body: @escaping () -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { _ in
            body()
        })
    }
}

/// Builder returned by generated `given` APIs for `rethrows` members with one argument.
public struct MockSynRethrowingStubBuilder1<Argument, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures one or more return values. Multiple values are returned sequentially.
    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    /// Configures the member to run a custom non-throwing closure receiving the call argument.
    public func willRun(_ body: @escaping (Argument) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(arguments[0] as! Argument)
        })
    }
}

/// Builder returned by generated `given` APIs for `rethrows` members with two arguments.
public struct MockSynRethrowingStubBuilder2<FirstArgument, SecondArgument, Return> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures one or more return values. Multiple values are returned sequentially.
    public func willReturn(_ values: Return...) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .returns(values))
    }

    /// Configures the member to run a custom non-throwing closure receiving both call arguments.
    public func willRun(_ body: @escaping (FirstArgument, SecondArgument) -> Return) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runsNonThrowing { arguments in
            body(arguments[0] as! FirstArgument, arguments[1] as! SecondArgument)
        })
    }
}

/// Generated property stubbing entrypoint for throwing getters.
public struct MockSynPropertyStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String

    public init(runtime: MockSynRuntime, getMember: String) {
        self.runtime = runtime
        self.getMember = getMember
    }

    public init(runtime: MockSynRuntime, getMember: String, setMember _: String) {
        self.init(runtime: runtime, getMember: getMember)
    }

    /// Builder for property getter behavior.
    public var get: MockSynStubBuilder<Value> {
        MockSynStubBuilder(runtime: runtime, member: getMember)
    }
}

/// Generated subscript stubbing entrypoint for throwing getters.
public struct MockSynSubscriptStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let indexMatchers: [MockSynAnyMatcher]

    public init(
        runtime: MockSynRuntime,
        getMember: String,
        indexMatchers: [MockSynAnyMatcher]
    ) {
        self.runtime = runtime
        self.getMember = getMember
        self.indexMatchers = indexMatchers
    }

    public init(
        runtime: MockSynRuntime,
        getMember: String,
        setMember _: String,
        indexMatchers: [MockSynAnyMatcher]
    ) {
        self.init(runtime: runtime, getMember: getMember, indexMatchers: indexMatchers)
    }

    /// Builder for subscript getter behavior.
    public var get: MockSynStubBuilder<Value> {
        MockSynStubBuilder(runtime: runtime, member: getMember, matchers: indexMatchers)
    }
}

/// Compatibility name for the non-throwing subscript setter builder.
public typealias MockSynSubscriptSetterStubBuilder<Value> = MockSynNonThrowingSubscriptSetterStubBuilder<Value>
