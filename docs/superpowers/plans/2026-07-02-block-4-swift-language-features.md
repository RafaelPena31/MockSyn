# Block 4 Swift Language Features Plan

## Scope

Implement syntax preservation and diagnostics for Swift language features used by
generated MockSyn doubles:

- generic methods;
- generic classes;
- `where` clauses;
- `Self` requirements where placeholder bodies can satisfy conformance;
- `inout` parameters;
- variadic parameters;
- closure and `@escaping` closure parameters;
- global actor attributes;
- `Sendable` protocol inheritance where Swift accepts the generated type;
- associated-type diagnostics.

## Implementation Notes

- Preserve generic parameter clauses and `where` clauses on generated methods.
- Mirror generic class parameters into generated subclasses and superclass
  references.
- Forward actor attributes whose names end in `Actor`.
- Delegate spy `inout` calls with `&`.
- Preserve variadic signatures. Later releases add finite synchronous spy
  delegation for one variadic parameter because Swift still does not provide a
  general splat for forwarding captured variadic arrays.
- Diagnose associated-type protocols instead of inferring bindings.

## Verification

- Macro expansion tests cover all supported syntax and diagnostics.
- Integration tests compile generated generic class doubles, `@MainActor` mocks,
  `inout` mocks, and delegating `inout` spies.
- Coverage must remain 100% for MockSyn source files.
