/// Access level used by MockSyn macros when emitting generated test doubles.
public enum MockSynAccess: Equatable, Sendable {
    /// Emits an `internal` generated type.
    case `internal`

    /// Emits a `public` generated type.
    case `public`

    /// Emits a `package` generated type.
    case `package`

    /// Emits a `fileprivate` generated type.
    case `fileprivate`

    /// Emits a `private` generated type.
    case `private`

    /// Source spelling used by macro-generated declarations.
    public var generatedSourceName: String {
        switch self {
        case .internal:
            return "internal"
        case .public:
            return "public"
        case .package:
            return "package"
        case .fileprivate:
            return "fileprivate"
        case .private:
            return "private"
        }
    }
}
