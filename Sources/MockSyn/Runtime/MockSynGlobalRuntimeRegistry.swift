import Foundation

private final class MockSynWeakRuntimeReference {
    weak var runtime: MockSynRuntime?

    init(_ runtime: MockSynRuntime) {
        self.runtime = runtime
    }
}

enum MockSynGlobalRuntimeRegistry {
    private static let lock = NSRecursiveLock()
    private static var references: [MockSynWeakRuntimeReference] = []

    static func register(_ runtime: MockSynRuntime) {
        lock.lock()
        defer { lock.unlock() }

        references.removeAll { $0.runtime == nil }
        references.append(MockSynWeakRuntimeReference(runtime))
    }

    static func runtimeSnapshot() -> [MockSynRuntime] {
        lock.lock()
        defer { lock.unlock() }

        let runtimes = references.compactMap(\.runtime)
        references.removeAll { $0.runtime == nil }
        return runtimes
    }
}
