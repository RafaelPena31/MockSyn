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

/// Runtime state sections that can be cleared from a test double.
public enum MockSynResetScope: Equatable, Sendable {
    /// Clears recorded invocations while keeping configured stubs.
    case invocations

    /// Clears configured stubs while keeping recorded invocations.
    case stubs

    /// Clears recorded invocations and configured stubs.
    case all
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
    private let changeCallback: (@Sendable () -> Void)?

    /// Creates runtime state for a generated test double.
    public init(
        kind: MockSynDoubleKind,
        mode: MockSynMode,
        onChange: (@Sendable () -> Void)? = nil
    ) {
        self.kind = kind
        self.mode = mode
        self.changeCallback = onChange
    }

    /// Creates runtime state registered for process-wide static-double cleanup.
    public static func global(kind: MockSynDoubleKind, mode: MockSynMode) -> MockSynRuntime {
        let runtime = MockSynRuntime(kind: kind, mode: mode)
        MockSynGlobalRuntimeRegistry.register(runtime)
        return runtime
    }

    /// Clears static-double runtimes and the process-wide MockSyn support state.
    ///
    /// Call this only at sequential test-suite boundaries, not while other tests
    /// are concurrently using MockSyn global state.
    public static func resetAllGlobalState() {
        let runtimes = MockSynGlobalRuntimeRegistry.runtimeSnapshot()
        for runtime in runtimes {
            runtime.reset()
        }

        MockSynDefaultValueRegistry.reset()
        MockSynFailureReporter.reset()
        MockSynInvocationClock.reset()
    }

    /// Registers a stub rule for a generated member.
    public func registerStub<Return>(
        member: String,
        matchers: [MockSynAnyMatcher],
        behavior: MockSynStubBehavior<Return>,
        notifyChange: Bool = false
    ) {
        lock.lock()
        stubs[member, default: []].append(MockSynStubRule(matchers: matchers, behavior: behavior.erase()))
        let callback = notifyChange ? changeCallback : nil
        lock.unlock()

        callback?()
    }

    /// Invokes the configured change callback without holding runtime state locks.
    public func notifyChange() {
        lock.lock()
        let callback = changeCallback
        lock.unlock()

        callback?()
    }

    /// Resolves a non-throwing generated member call.
    ///
    /// Strict missing stubs are reported before a custom or built-in default is
    /// returned. Resolution terminates only when no value can satisfy `Return`.
    public func resolve<Return>(
        member: String,
        arguments: [Any],
        returnType: Return.Type,
        fallback: (() -> Return)? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> Return {
        recordInvocation(member: member, arguments: arguments)

        if case .value(let value) = resolveNonThrowingStub(member: member, arguments: arguments) {
            return value as! Return
        }

        if let fallback {
            return fallback()
        }

        let defaultValue = MockSynDefaultValueRegistry.value(for: Return.self)
        let error = MockSynRuntimeError.missingStub(member: member)
        let reportedRecoverableFailure = mode == .strict && Return.self != Void.self

        if reportedRecoverableFailure {
            report(
                error,
                file: file,
                line: line,
                details: receivedCallDescription(member: member, arguments: arguments)
            )
        }

        if let defaultValue {
            return defaultValue
        }

        if !reportedRecoverableFailure {
            report(
                error,
                file: file,
                line: line,
                details: receivedCallDescription(member: member, arguments: arguments)
            )
        }

        fatalError(
            "MockSyn member \(member) has no configured value for \(String(reflecting: Return.self)). "
                + "Configure it with willReturn(...) or register a default with "
                + "MockSynDefaultValueRegistry.register(_:for:).",
            file: file,
            line: line
        )
    }

    /// Resolves a throwing generated member call.
    public func resolveThrowing<Return>(
        member: String,
        arguments: [Any],
        returnType: Return.Type,
        fallback: (() throws -> Return)? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) throws -> Return {
        recordInvocation(member: member, arguments: arguments)

        if let value = try resolveStub(member: member, arguments: arguments) {
            return value as! Return
        }

        if let fallback {
            return try fallback()
        }

        if let defaultValue = MockSynDefaultValueRegistry.value(for: Return.self),
           Return.self == Void.self || mode == .relaxed {
            return defaultValue
        }

        let error = MockSynRuntimeError.missingStub(member: member)
        report(error, file: file, line: line, details: receivedCallDescription(member: member, arguments: arguments))
        throw error
    }

    /// Resolves a non-throwing generated void member call.
    public func resolveVoid(
        member: String,
        arguments: [Any],
        fallback: (() -> Void)? = nil,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        let _: Void = resolve(
            member: member,
            arguments: arguments,
            returnType: Void.self,
            fallback: fallback,
            file: file,
            line: line
        )
    }

    /// Resolves a generated `rethrows` member call while allowing only the fallback closure to throw.
    public func resolveRethrowing<Return>(
        member: String,
        arguments: [Any],
        returnType: Return.Type,
        fallback: () throws -> Return
    ) rethrows -> Return {
        recordInvocation(member: member, arguments: arguments)

        if case .value(let value) = resolveNonThrowingStub(member: member, arguments: arguments) {
            return value as! Return
        }

        return try fallback()
    }

    /// Resolves a generated void `rethrows` member call while allowing only the fallback closure to throw.
    public func resolveVoidRethrowing(member: String, arguments: [Any], fallback: () throws -> Void) rethrows {
        let _: Void = try resolveRethrowing(member: member, arguments: arguments, returnType: Void.self, fallback: fallback)
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
    public func verify(
        member: String,
        matchers: [MockSynAnyMatcher],
        count: MockSynVerificationCount,
        file: StaticString = #fileID,
        line: UInt = #line
    ) throws {
        let snapshot = invocationSnapshot()
        let matchingInvocations = matchingInvocations(
            in: snapshot,
            member: member,
            matchers: matchers
        )
        guard count.matches(matchingInvocations.count) else {
            let error = MockSynVerificationError.expected(
                member: member,
                count: count,
                actual: matchingInvocations.count,
                recordedCalls: recordedCallDescriptions(in: snapshot, member: member)
            )
            report(error, file: file, line: line)
            throw error
        }

        lock.lock()
        defer { lock.unlock() }

        for invocation in matchingInvocations {
            invocation.isVerified = true
        }
    }

    /// Fails when any recorded invocation has not been verified.
    public func confirmVerified(file: StaticString = #fileID, line: UInt = #line) throws {
        lock.lock()
        let unverifiedMembers = invocations
            .filter { !$0.isVerified }
            .map(\.member)
        lock.unlock()

        guard unverifiedMembers.isEmpty else {
            let error = MockSynVerificationError.unverifiedInvocations(unverifiedMembers)
            report(error, file: file, line: line, details: recordedCallsDescription())
            throw error
        }
    }

    /// Fails when configured stubs were never matched by a call.
    public func checkUnnecessaryStubs(file: StaticString = #fileID, line: UInt = #line) throws {
        lock.lock()
        let unusedMembers = stubs.flatMap { member, rules in
            rules.filter { !$0.wasUsed }.map { _ in member }
        }
        lock.unlock()

        guard unusedMembers.isEmpty else {
            let error = MockSynVerificationError.unnecessaryStubs(unusedMembers)
            report(error, file: file, line: line, details: "Configured stubs: \(unusedMembers.joined(separator: ", "))")
            throw error
        }
    }

    /// Clears recorded invocations, configured stubs, or both.
    public func reset(_ scope: MockSynResetScope = .all) {
        lock.lock()
        defer { lock.unlock() }

        switch scope {
        case .invocations:
            invocations.removeAll(keepingCapacity: true)
        case .stubs:
            stubs.removeAll(keepingCapacity: true)
        case .all:
            invocations.removeAll(keepingCapacity: true)
            stubs.removeAll(keepingCapacity: true)
        }
    }

    func firstInvocationSequence(
        member: String,
        matchers: [MockSynAnyMatcher],
        file: StaticString = #fileID,
        line: UInt = #line
    ) throws -> MockSynInvocationSequence {
        let snapshot = invocationSnapshot()
        guard let invocation = matchingInvocations(in: snapshot, member: member, matchers: matchers).first else {
            let error = MockSynVerificationError.expected(
                member: member,
                count: .atLeast(1),
                actual: 0,
                recordedCalls: recordedCallDescriptions(in: snapshot, member: member)
            )
            report(error, file: file, line: line)
            throw error
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
        matchingInvocations(in: invocationSnapshot(), member: member, matchers: matchers)
    }

    private func invocationSnapshot() -> [MockSynInvocation] {
        lock.lock()
        let snapshot = invocations
        lock.unlock()

        return snapshot
    }

    private func matchingInvocations(
        in snapshot: [MockSynInvocation],
        member: String,
        matchers: [MockSynAnyMatcher]
    ) -> [MockSynInvocation] {
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

    private func resolveNonThrowingStub(
        member: String,
        arguments: [Any]
    ) -> MockSynNonThrowingStubResolution {
        lock.lock()
        defer { lock.unlock() }

        guard let rules = stubs[member] else {
            return .unavailable
        }

        for rule in rules where rule.matches(arguments) {
            return rule.resolveNonThrowing(arguments)
        }

        return .unavailable
    }

    private func report(
        _ error: some CustomStringConvertible,
        file: StaticString,
        line: UInt,
        details: String? = nil
    ) {
        let message = details.map { "\(error)\n\($0)" } ?? String(describing: error)
        MockSynFailureReporter.report(MockSynFailure(message: message, file: file, line: line))
    }

    private func receivedCallDescription(member: String, arguments: [Any]) -> String {
        "Received call:\n- \(Self.callDescription(member: member, arguments: arguments))"
    }

    private func recordedCallsDescription(member: String? = nil) -> String {
        let descriptions = recordedCallDescriptions(in: invocationSnapshot(), member: member)
        guard !descriptions.isEmpty else {
            return "Recorded calls: none"
        }

        return "Recorded calls:\n" + descriptions
            .map { "- \($0)" }
            .joined(separator: "\n")
    }

    private func recordedCallDescriptions(
        in snapshot: [MockSynInvocation],
        member: String? = nil
    ) -> [String] {
        snapshot.compactMap { invocation in
            member == nil || invocation.member == member
                ? Self.callDescription(member: invocation.member, arguments: invocation.arguments)
                : nil
        }
    }

    static func arguments(_ arguments: [Any], match matchers: [MockSynAnyMatcher]) -> Bool {
        guard arguments.count == matchers.count else {
            return false
        }

        return zip(matchers, arguments).allSatisfy { matcher, argument in
            matcher.matches(argument)
        }
    }

    private static func argumentDescription(_ arguments: [Any]) -> String {
        arguments.map(MockSynArgumentRenderer.render).joined(separator: ", ")
    }

    private static func callDescription(member: String, arguments: [Any]) -> String {
        guard !arguments.isEmpty else {
            return member
        }

        return "\(member)(\(argumentDescription(arguments)))"
    }
}
