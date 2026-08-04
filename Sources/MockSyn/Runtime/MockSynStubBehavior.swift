import Foundation

enum MockSynNonThrowingStubResolution {
    case value(Any)
    case unavailable
}

/// Stub behavior configured through generated `given` APIs.
public struct MockSynStubBehavior<Return> {
    private let resolver: ([Any]) throws -> Return
    private let nonThrowingResolver: ([Any]) -> MockSynNonThrowingStubResolution

    private init(nonThrowingResolver: @escaping ([Any]) -> Return) {
        self.resolver = nonThrowingResolver
        self.nonThrowingResolver = { arguments in
            .value(nonThrowingResolver(arguments))
        }
    }

    private init(
        throwingResolver: @escaping ([Any]) throws -> Return,
        supportsNonThrowingResolution: Bool = false
    ) {
        self.resolver = throwingResolver
        self.nonThrowingResolver = { arguments in
            guard supportsNonThrowingResolution else {
                return .unavailable
            }

            do {
                return .value(try throwingResolver(arguments))
            } catch {
                return .unavailable
            }
        }
    }

    /// Returns values sequentially. After the sequence is exhausted, the last value is reused.
    public static func returns(_ values: [Return]) -> MockSynStubBehavior<Return> {
        let sequence = MockSynReturnSequence(values: values)
        return MockSynStubBehavior(nonThrowingResolver: { _ in
            sequence.next()
        })
    }

    /// Throws the configured error.
    public static func throwing(_ error: Error) -> MockSynStubBehavior<Return> {
        MockSynStubBehavior(throwingResolver: { _ in
            throw error
        })
    }

    /// Executes a custom non-throwing closure.
    public static func runs(_ body: @escaping ([Any]) -> Return) -> MockSynStubBehavior<Return> {
        MockSynStubBehavior(nonThrowingResolver: body)
    }

    /// Executes a custom closure.
    public static func runs(_ body: @escaping ([Any]) throws -> Return) -> MockSynStubBehavior<Return> {
        MockSynStubBehavior(throwingResolver: body, supportsNonThrowingResolution: true)
    }

    func erase() -> MockSynErasedStubBehavior {
        MockSynErasedStubBehavior(
            resolver: { arguments in try resolver(arguments) },
            nonThrowingResolver: nonThrowingResolver
        )
    }
}

struct MockSynErasedStubBehavior {
    private let resolver: ([Any]) throws -> Any
    private let nonThrowingResolver: ([Any]) -> MockSynNonThrowingStubResolution

    init(
        resolver: @escaping ([Any]) throws -> Any,
        nonThrowingResolver: @escaping ([Any]) -> MockSynNonThrowingStubResolution
    ) {
        self.resolver = resolver
        self.nonThrowingResolver = nonThrowingResolver
    }

    func resolve(_ arguments: [Any]) throws -> Any {
        try resolver(arguments)
    }

    func resolveNonThrowing(_ arguments: [Any]) -> MockSynNonThrowingStubResolution {
        nonThrowingResolver(arguments)
    }
}

private final class MockSynReturnSequence<Return>: @unchecked Sendable {
    private var values: [Return]
    private var index = 0
    private let lock = NSRecursiveLock()

    init(values: [Return]) {
        self.values = values
    }

    func next() -> Return {
        lock.lock()
        defer { lock.unlock() }

        let last = values[values.count - 1]

        guard index < values.count else {
            return last
        }

        let value = values[index]
        index += 1
        return value
    }
}
