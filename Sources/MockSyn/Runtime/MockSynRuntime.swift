import Foundation

/// Errors produced by MockSyn runtime resolution paths.
public enum MockSynRuntimeError: Error, Equatable, CustomStringConvertible {
    /// A strict generated double received a non-void call without a matching stub.
    case missingStub(member: String)

    public var description: String {
        switch self {
        case .missingStub(let member):
            return "MockSyn member \(member) is not configured"
        }
    }
}

/// Runtime state shared by generated MockSyn test doubles.
public final class MockSynRuntime: @unchecked Sendable {
    /// The generated double kind.
    public let kind: MockSynDoubleKind

    /// The default behavior for unstubbed calls.
    public let mode: MockSynMode

    private let lock = NSRecursiveLock()
    private var stubs: [String: [MockSynStubRule]] = [:]
    private var invocations: [MockSynInvocation] = []

    /// Creates runtime state for a generated test double.
    public init(kind: MockSynDoubleKind, mode: MockSynMode) {
        self.kind = kind
        self.mode = mode
    }

    /// Registers a stub rule for a generated member.
    public func registerStub<Return>(
        member: String,
        matchers: [MockSynAnyMatcher],
        behavior: MockSynStubBehavior<Return>
    ) {
        lock.lock()
        defer { lock.unlock() }

        stubs[member, default: []].append(MockSynStubRule(matchers: matchers, behavior: behavior.erase()))
    }

    /// Resolves a non-throwing generated member call.
    public func resolve<Return>(
        member: String,
        arguments: [Any],
        returnType: Return.Type,
        fallback: (() -> Return)? = nil
    ) -> Return {
        try! resolveThrowing(member: member, arguments: arguments, returnType: returnType, fallback: fallback)
    }

    /// Resolves a throwing generated member call.
    public func resolveThrowing<Return>(
        member: String,
        arguments: [Any],
        returnType: Return.Type,
        fallback: (() throws -> Return)? = nil
    ) throws -> Return {
        recordInvocation(member: member, arguments: arguments)

        if let value = try resolveStub(member: member, arguments: arguments) {
            return value as! Return
        }

        if let fallback {
            return try fallback()
        }

        if let defaultValue = MockSynDefaultValueRegistry.value(for: Return.self),
           Return.self == Void.self || mode == .relaxed || kind == .stub {
            return defaultValue
        }

        throw MockSynRuntimeError.missingStub(member: member)
    }

    /// Resolves a non-throwing generated void member call.
    public func resolveVoid(member: String, arguments: [Any], fallback: (() -> Void)? = nil) {
        let _: Void = resolve(member: member, arguments: arguments, returnType: Void.self, fallback: fallback)
    }

    /// Resolves a throwing generated void member call.
    public func resolveVoidThrowing(member: String, arguments: [Any], fallback: (() throws -> Void)? = nil) throws {
        let _: Void = try resolveThrowing(member: member, arguments: arguments, returnType: Void.self, fallback: fallback)
    }

    /// Records a generated member call without resolving stubs.
    public func record(member: String, arguments: [Any]) {
        recordInvocation(member: member, arguments: arguments)
    }

    /// Verifies recorded invocations for a generated member and marks matching calls as verified.
    public func verify(member: String, matchers: [MockSynAnyMatcher], count: MockSynVerificationCount) throws {
        let matchingInvocations = matchingInvocations(member: member, matchers: matchers)
        guard count.matches(matchingInvocations.count) else {
            throw MockSynVerificationError.expected(member: member, count: count, actual: matchingInvocations.count)
        }

        lock.lock()
        defer { lock.unlock() }

        for invocation in matchingInvocations {
            invocation.isVerified = true
        }
    }

    /// Fails when any recorded invocation has not been verified.
    public func confirmVerified() throws {
        lock.lock()
        let unverifiedMembers = invocations
            .filter { !$0.isVerified }
            .map(\.member)
        lock.unlock()

        guard unverifiedMembers.isEmpty else {
            throw MockSynVerificationError.unverifiedInvocations(unverifiedMembers)
        }
    }

    /// Fails when configured stubs were never matched by a call.
    public func checkUnnecessaryStubs() throws {
        lock.lock()
        let unusedMembers = stubs.flatMap { member, rules in
            rules.filter { !$0.wasUsed }.map { _ in member }
        }
        lock.unlock()

        guard unusedMembers.isEmpty else {
            throw MockSynVerificationError.unnecessaryStubs(unusedMembers)
        }
    }

    func firstInvocationSequence(member: String, matchers: [MockSynAnyMatcher]) throws -> UInt64 {
        guard let invocation = matchingInvocations(member: member, matchers: matchers).first else {
            throw MockSynVerificationError.expected(member: member, count: .atLeast(1), actual: 0)
        }

        return invocation.sequence
    }

    func invocationCount(member: String, matchers: [MockSynAnyMatcher]) -> Int {
        matchingInvocations(member: member, matchers: matchers).count
    }

    private func recordInvocation(member: String, arguments: [Any]) {
        lock.lock()
        defer { lock.unlock() }

        invocations.append(MockSynInvocation(member: member, arguments: arguments, sequence: MockSynInvocationClock.next()))
    }

    private func matchingInvocations(member: String, matchers: [MockSynAnyMatcher]) -> [MockSynInvocation] {
        lock.lock()
        let snapshot = invocations
        lock.unlock()

        return snapshot.filter { invocation in
            invocation.member == member && MockSynRuntime.arguments(invocation.arguments, match: matchers)
        }
    }

    private func resolveStub(member: String, arguments: [Any]) throws -> Any? {
        lock.lock()
        defer { lock.unlock() }

        guard let rules = stubs[member] else {
            return nil
        }

        for rule in rules where rule.matches(arguments) {
            return try rule.resolve(arguments)
        }

        return nil
    }

    fileprivate static func arguments(_ arguments: [Any], match matchers: [MockSynAnyMatcher]) -> Bool {
        guard arguments.count == matchers.count else {
            return false
        }

        return zip(matchers, arguments).allSatisfy { matcher, argument in
            matcher.matches(argument)
        }
    }
}

private final class MockSynStubRule: @unchecked Sendable {
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

private final class MockSynInvocation: @unchecked Sendable {
    let member: String
    let arguments: [Any]
    let sequence: UInt64
    var isVerified = false

    init(member: String, arguments: [Any], sequence: UInt64) {
        self.member = member
        self.arguments = arguments
        self.sequence = sequence
    }
}

private enum MockSynInvocationClock {
    private static let lock = NSRecursiveLock()
    private static var current: UInt64 = 0

    static func next() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }

        current += 1
        return current
    }
}
