import Foundation

/// Token that owns a temporary constructor replacement.
///
/// Keep the token alive for the desired replacement scope. Calling ``restore()``
/// or releasing the token restores the previous constructor implementation.
public final class MockSynConstructorInterception: @unchecked Sendable {
    private let lock = NSLock()
    private let restoreAction: () -> Void
    private var isRestored = false

    init(restoreAction: @escaping () -> Void) {
        self.restoreAction = restoreAction
    }

    deinit {
        restore()
    }

    /// Restores the constructor implementation that was active before replacement.
    public func restore() {
        lock.lock()
        defer { lock.unlock() }

        guard !isRestored else {
            return
        }

        restoreAction()
        isRestored = true
    }
}

private final class MockSynConstructorStorage<Implementation>: @unchecked Sendable {
    private let lock = NSLock()
    private var implementation: Implementation

    init(_ implementation: Implementation) {
        self.implementation = implementation
    }

    func current() -> Implementation {
        lock.lock()
        defer { lock.unlock() }

        return implementation
    }

    func replace(with replacement: Implementation) -> MockSynConstructorInterception {
        lock.lock()
        let previous = implementation
        implementation = replacement
        lock.unlock()

        return MockSynConstructorInterception { [self] in
            setImplementation(previous)
        }
    }

    private func setImplementation(_ implementation: Implementation) {
        lock.lock()
        defer { lock.unlock() }

        self.implementation = implementation
    }
}

/// Explicit zero-argument constructor seam for tests.
///
/// MockSyn cannot intercept arbitrary `Type(...)` call sites. Use this type when
/// production code can receive a factory closure and tests need scoped
/// replacement of that constructor behavior.
public final class MockSynConstructor<Output>: @unchecked Sendable {
    private let storage: MockSynConstructorStorage<() -> Output>

    /// Creates a constructor seam backed by the original constructor behavior.
    public init(_ constructor: @escaping () -> Output) {
        self.storage = MockSynConstructorStorage(constructor)
    }

    /// Runs the constructor implementation that is active for the current scope.
    public func callAsFunction() -> Output {
        storage.current()()
    }

    /// Replaces the active constructor until the returned token is restored.
    @discardableResult
    public func replace(with replacement: @escaping () -> Output) -> MockSynConstructorInterception {
        storage.replace(with: replacement)
    }
}

/// Explicit one-argument constructor seam for tests.
public final class MockSynConstructor1<Argument, Output>: @unchecked Sendable {
    private let storage: MockSynConstructorStorage<(Argument) -> Output>

    /// Creates a constructor seam backed by the original constructor behavior.
    public init(_ constructor: @escaping (Argument) -> Output) {
        self.storage = MockSynConstructorStorage(constructor)
    }

    /// Runs the constructor implementation that is active for the current scope.
    public func callAsFunction(_ argument: Argument) -> Output {
        storage.current()(argument)
    }

    /// Replaces the active constructor until the returned token is restored.
    @discardableResult
    public func replace(with replacement: @escaping (Argument) -> Output) -> MockSynConstructorInterception {
        storage.replace(with: replacement)
    }
}

/// Explicit two-argument constructor seam for tests.
public final class MockSynConstructor2<FirstArgument, SecondArgument, Output>: @unchecked Sendable {
    private let storage: MockSynConstructorStorage<(FirstArgument, SecondArgument) -> Output>

    /// Creates a constructor seam backed by the original constructor behavior.
    public init(_ constructor: @escaping (FirstArgument, SecondArgument) -> Output) {
        self.storage = MockSynConstructorStorage(constructor)
    }

    /// Runs the constructor implementation that is active for the current scope.
    public func callAsFunction(_ firstArgument: FirstArgument, _ secondArgument: SecondArgument) -> Output {
        storage.current()(firstArgument, secondArgument)
    }

    /// Replaces the active constructor until the returned token is restored.
    @discardableResult
    public func replace(
        with replacement: @escaping (FirstArgument, SecondArgument) -> Output
    ) -> MockSynConstructorInterception {
        storage.replace(with: replacement)
    }
}
