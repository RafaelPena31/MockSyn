# Block 2 Supported Types Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development while implementing this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Block 2 from `docs/FEATURES.md`: supported declaration types for MockSyn macros.

**Architecture:** Keep the macro-only flow from Block 1. Extend `MockSynPeerMacro` so it treats supported protocols and supported classes as distinct generation targets while reusing option parsing, access validation, naming validation, and diagnostics.

**Tech Stack:** SwiftPM, Swift macros, SwiftSyntax, SwiftSyntaxMacrosTestSupport, XCTest, Foundation for `NSObject` integration fixtures.

---

### Task 1: Protocol Type Support

**Files:**
- Modify: `Tests/MockSynMacroTests/MockSynMacroTests.swift`
- Modify: `Tests/MockSynTests/MockSynGeneratedTypeIntegrationTests.swift`

- [x] Add failing macro expansion coverage for simple protocol inheritance.
- [x] Add failing integration coverage proving a generated mock for an inherited protocol can be used as the parent protocol type.

### Task 2: Non-Final Class Support

**Files:**
- Modify: `Tests/MockSynMacroTests/MockSynMacroTests.swift`
- Modify: `Tests/MockSynTests/MockSynGeneratedTypeIntegrationTests.swift`
- Modify: `Sources/MockSynMacros/MockSynPeerMacro.swift`

- [x] Add failing macro expansion coverage for `@Mocking`, `@Stubbing`, and `@Spying` on non-final classes.
- [x] Add failing integration coverage proving generated class doubles subclass the annotated class.
- [x] Implement subclass generation with `super.init()`.

### Task 3: NSObject And Objective-C-Annotated Classes

**Files:**
- Modify: `Tests/MockSynMacroTests/MockSynMacroTests.swift`
- Modify: `Tests/MockSynTests/MockSynGeneratedTypeIntegrationTests.swift`
- Modify: `Sources/MockSynMacros/MockSynPeerMacro.swift`

- [x] Add failing macro expansion coverage for `@objcMembers class LegacyService: NSObject`.
- [x] Add failing integration coverage proving generated doubles subclass `NSObject`-backed classes.
- [x] Keep Objective-C runtime interception out of the core implementation.

### Task 4: Diagnostics And Docs

**Files:**
- Modify: `Tests/MockSynMacroTests/MockSynMacroTests.swift`
- Create: `docs/features/supported-types.md`
- Modify: `docs/README.md`
- Modify: `docs/LIMITATIONS.md`

- [x] Preserve final class diagnostic.
- [x] Add coverage for visibility widening on classes.
- [x] Document supported types, unsupported final classes, and Objective-C runtime limitations.

### Task 5: Verification

**Files:**
- Package and generated coverage output.

- [x] Run `swift test`.
- [x] Run `swift test --enable-code-coverage`.
- [x] Confirm 100% line coverage for `Sources/MockSyn` and `Sources/MockSynMacros`.
- [x] Run `swift build -c release`.
