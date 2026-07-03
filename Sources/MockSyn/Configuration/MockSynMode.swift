/// Default behavior used when a generated test double receives an unstubbed call.
public enum MockSynMode: Equatable, Sendable {
    /// Requires explicit stubs for calls that need a value.
    case strict

    /// Allows generated doubles to return default values when supported.
    case relaxed

    /// Source spelling used by macro-generated declarations.
    public var generatedSourceName: String {
        switch self {
        case .strict:
            return ".strict"
        case .relaxed:
            return ".relaxed"
        }
    }
}
