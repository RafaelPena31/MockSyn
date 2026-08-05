/// Generates a mock peer type for the annotated protocol.
///
/// Generated declarations inherit the annotated declaration's access and are
/// wrapped in `#if MOCKSYN_ENABLE` by default.
@attached(peer, names: prefixed(Mock), suffixed(Mock))
public macro Mocking(
    name: String? = nil,
    access: MockSynAccess = .inherited,
    mode: MockSynMode = .strict
) = #externalMacro(module: "MockSynMacros", type: "MockingMacro")

/// Generates a stub peer type for the annotated protocol.
///
/// Stubs inherit the annotated declaration's access and default to relaxed mode
/// because they focus on preconfigured responses.
@attached(peer, names: prefixed(Stub), suffixed(Stub))
public macro Stubbing(
    name: String? = nil,
    access: MockSynAccess = .inherited,
    mode: MockSynMode = .relaxed
) = #externalMacro(module: "MockSynMacros", type: "StubbingMacro")

/// Generates a spy peer type for the annotated protocol.
///
/// Spies inherit the annotated declaration's access and keep a wrapped
/// implementation so generated members can delegate when supported.
@attached(peer, names: prefixed(Spy), suffixed(Spy))
public macro Spying(
    name: String? = nil,
    access: MockSynAccess = .inherited,
    mode: MockSynMode = .strict
) = #externalMacro(module: "MockSynMacros", type: "SpyingMacro")
