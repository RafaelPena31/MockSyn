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
}

private final class MockSynStubRule: @unchecked Sendable {
    private let matchers: [MockSynAnyMatcher]
    private var behavior: MockSynErasedStubBehavior

    init(matchers: [MockSynAnyMatcher], behavior: MockSynErasedStubBehavior) {
        self.matchers = matchers
        self.behavior = behavior
    }

    func matches(_ arguments: [Any]) -> Bool {
        guard arguments.count == matchers.count else {
            return false
        }

        return zip(matchers, arguments).allSatisfy { matcher, argument in
            matcher.matches(argument)
        }
    }

    func resolve(_ arguments: [Any]) throws -> Any {
        try behavior.resolve(arguments)
    }
}
