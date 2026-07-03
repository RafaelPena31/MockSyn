# Block 1 Macros Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development while implementing this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Block 1 macro surface from `docs/FEATURES.md`: `@Mocking`, `@Stubbing`, `@Spying`, generated name configuration, strict/relaxed configuration, and generated visibility configuration.

**Architecture:** `MockSyn` exposes public macro declarations and the small runtime types needed by generated declarations. `MockSynMacros` parses macro attributes, validates supported declarations, and emits compact peer declarations wrapped in `#if MOCKSYN_ENABLE`.

**Tech Stack:** SwiftPM, Swift macros, SwiftSyntax, SwiftSyntaxMacros, SwiftDiagnostics, XCTest, SwiftSyntaxMacrosTestSupport.

---

### Task 1: Package Setup

**Files:**
- Modify: `Package.swift`
- Delete: `Sources/MockSynClient/main.swift`
- Create: `Tests/MockSynMacroTests/MockSynMacroTests.swift`
- Modify: `Tests/MockSynTests/MockSynTests.swift`

- [x] Remove the template executable product and target.
- [x] Split macro expansion tests into `MockSynMacroTests`.
- [x] Keep runtime/public API tests in `MockSynTests`.
- [x] Keep SwiftSyntax dependencies only in macro and macro test targets.

### Task 2: Macro API Declarations

**Files:**
- Modify: `Sources/MockSyn/MockSyn.swift`
- Create: `Sources/MockSyn/Configuration/MockSynAccess.swift`
- Create: `Sources/MockSyn/Configuration/MockSynMode.swift`
- Create: `Sources/MockSyn/Runtime/MockSynDoubleKind.swift`
- Create: `Sources/MockSyn/Runtime/MockSynRuntime.swift`
- Test: `Tests/MockSynTests/MockSynPublicAPITests.swift`

- [x] Write failing tests for public configuration defaults and raw generated spellings.
- [x] Define `MockSynAccess`, `MockSynMode`, `MockSynDoubleKind`, and `MockSynRuntime`.
- [x] Replace `#stringify` with attached peer macros for `@Mocking`, `@Stubbing`, and `@Spying`.
- [x] Add public doc strings for every public API symbol.

### Task 3: Macro Expansion

**Files:**
- Modify: `Sources/MockSynMacros/MockSynMacro.swift`
- Create: `Sources/MockSynMacros/MockSynPeerMacro.swift`
- Create: `Sources/MockSynMacros/MockSynMacroOptions.swift`
- Create: `Sources/MockSynMacros/MockSynDiagnostics.swift`
- Test: `Tests/MockSynMacroTests/MockSynMacroTests.swift`

- [x] Write failing expansion tests for default mock, stub, and spy generation.
- [x] Write failing expansion tests for custom `name`, `access`, and `mode`.
- [x] Implement syntax-only option parsing.
- [x] Generate declarations under `#if MOCKSYN_ENABLE`.
- [x] Emit deterministic, compact generated code.

### Task 4: Diagnostics

**Files:**
- Modify: `Sources/MockSynMacros/MockSynDiagnostics.swift`
- Test: `Tests/MockSynMacroTests/MockSynMacroTests.swift`

- [x] Write failing diagnostic tests for unsupported declarations.
- [x] Write failing diagnostic tests for pure Swift final classes.
- [x] Write failing diagnostic tests for invalid access values.
- [x] Implement diagnostics with stable messages.

### Task 5: Documentation And Verification

**Files:**
- Create: `docs/features/macros.md`
- Modify: `docs/API_DESIGN.md` if the implemented Block 1 surface needs clarification.
- Modify: `docs/SUPPORT_MATRIX.md` if package/toolchain strategy changes.

- [x] Document `@Mocking`, `@Stubbing`, `@Spying`, `name`, `access`, and `mode`.
- [x] Document current Block 1 limitations versus later blocks.
- [x] Run `swift test`.
- [x] Run `swift test --enable-code-coverage`.
- [x] Inspect coverage output and address uncovered project code where practical.
