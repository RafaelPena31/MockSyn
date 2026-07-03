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
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { _ in
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
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
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
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            body(arguments[0] as! FirstArgument, arguments[1] as! SecondArgument)
        })
    }
}

/// Generated property stubbing entrypoint.
public struct MockSynPropertyStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String

    public init(runtime: MockSynRuntime, getMember: String, setMember: String) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
    }

    /// Builder for property getter behavior.
    public var get: MockSynStubBuilder<Value> {
        MockSynStubBuilder(runtime: runtime, member: getMember)
    }

    /// Builder for property setter behavior.
    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynStubBuilder1<Value, Void> {
        MockSynStubBuilder1(runtime: runtime, member: setMember, matchers: [matcher.erase()])
    }
}

/// Generated subscript stubbing entrypoint.
public struct MockSynSubscriptStubber<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String
    private let indexMatchers: [MockSynAnyMatcher]

    public init(
        runtime: MockSynRuntime,
        getMember: String,
        setMember: String,
        indexMatchers: [MockSynAnyMatcher]
    ) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
        self.indexMatchers = indexMatchers
    }

    /// Builder for subscript getter behavior.
    public var get: MockSynStubBuilder<Value> {
        MockSynStubBuilder(runtime: runtime, member: getMember, matchers: indexMatchers)
    }

    /// Builder for subscript setter behavior.
    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynSubscriptSetterStubBuilder<Value> {
        MockSynSubscriptSetterStubBuilder(runtime: runtime, member: setMember, matchers: indexMatchers + [matcher.erase()])
    }
}

/// Builder returned by generated subscript setter stubbing APIs.
public struct MockSynSubscriptSetterStubBuilder<Value> {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Configures the setter to throw an error when executed through a throwing member path.
    public func willThrow(_ error: Error) {
        runtime.registerStub(member: member, matchers: matchers, behavior: MockSynStubBehavior<Void>.throwing(error))
    }

    /// Configures the setter to run a custom closure receiving the assigned value.
    public func willRun(_ body: @escaping (Value) throws -> Void) {
        runtime.registerStub(member: member, matchers: matchers, behavior: .runs { arguments in
            try body(arguments[arguments.count - 1] as! Value)
        })
    }
}
