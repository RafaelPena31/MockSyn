import Foundation

/// Runtime failure captured before MockSyn throws or crashes.
public struct MockSynFailure: Equatable, Sendable {
    /// Human-readable failure message.
    public let message: String

    /// Source file associated with the runtime reporting point.
    public let file: String

    /// Source line associated with the runtime reporting point.
    public let line: UInt

    public init(message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.message = message
        self.file = "\(file)"
        self.line = line
    }
}

/// Lightweight process-wide failure reporting channel used by MockSyn runtime errors.
public enum MockSynFailureReporter {
    private static let lock = NSRecursiveLock()
    private static var handler: (@Sendable (MockSynFailure) -> Void)?

    /// Installs a custom failure handler. Passing `nil` disables reporting.
    public static func setHandler(_ newHandler: (@Sendable (MockSynFailure) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }

        handler = newHandler
    }

    /// Restores the default no-op reporter.
    public static func reset() {
        setHandler(nil)
    }

    /// Reports an error through the configured handler.
    public static func report(_ error: some CustomStringConvertible, file: StaticString = #fileID, line: UInt = #line) {
        report(MockSynFailure(message: String(describing: error), file: file, line: line))
    }

    /// Reports a concrete failure through the configured handler.
    public static func report(_ failure: MockSynFailure) {
        lock.lock()
        let currentHandler = handler
        lock.unlock()

        currentHandler?(failure)
    }
}
