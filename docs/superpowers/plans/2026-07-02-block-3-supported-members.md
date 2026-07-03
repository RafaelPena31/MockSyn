# Block 3 Supported Members Plan

## Scope

Implement member generation for declarations already accepted by MockSyn:

- sync, `throws`, `async`, and `async throws` methods;
- `Void` methods;
- `get` and `get set` properties;
- protocol static requirements;
- subscripts;
- protocol initializer requirements for mocks and stubs;
- overload-friendly generation by preserving Swift signatures;
- diagnostics for operator requirements.

## Implementation Notes

- Keep the runtime minimal. Do not add stubbing, verification, invocation
  storage, matchers, captors, relaxed defaults, or failure reporters in this
  block.
- Generate placeholder behavior for mocks and stubs:
  - `Void` methods and setters are callable no-ops.
  - Non-void methods, getters, and subscripts call `fatalError` until stubbing
    exists.
- Generate spy delegation for supported instance methods and readable members
  when the wrapped implementation can be called directly.
- Limit generated initializer requirements to protocols for mocks and stubs in
  Block 3. Later releases add class initializer mirroring for non-variadic class
  initializers where Swift subclassing supports forwarding.

## Verification

- Macro expansion tests cover generated source for methods, properties, static
  requirements, subscripts, initializers, class overrides, spy delegation, and
  diagnostics.
- Integration tests compile generated members and call safe generated behavior.
- Coverage must remain 100% for MockSyn source files.
