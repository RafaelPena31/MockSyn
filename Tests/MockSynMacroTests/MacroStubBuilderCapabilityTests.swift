import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testCapabilityAndArityBuilderExpansion() {
        assertExpansion(
            """
            @Mocking
            protocol CapabilityService {
                var title: String { get set }
                var throwingTitle: String { get throws }
                subscript(index: Int) -> String { get set }
                subscript(throwing index: String) -> String { get throws }
                func three(_ a: Int, _ b: String, _ c: Bool) -> String
                func four(_ a: Int, _ b: Int, _ c: Int, _ d: Int) throws -> Int
                func five(_ operation: @escaping () throws -> Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int) rethrows -> Int
                func six(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int) -> Int
                func many(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) -> Int
                func throwingMany(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) throws -> Int
                func rethrowingMany(_ operation: @escaping () throws -> Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) rethrows -> Int
            }
            """,
            expandedSource: """
              protocol CapabilityService {
                  var title: String { get set }
                  var throwingTitle: String { get throws }
                  subscript(index: Int) -> String { get set }
                  subscript(throwing index: String) -> String { get throws }
                  func three(_ a: Int, _ b: String, _ c: Bool) -> String
                  func four(_ a: Int, _ b: Int, _ c: Int, _ d: Int) throws -> Int
                  func five(_ operation: @escaping () throws -> Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int) rethrows -> Int
                  func six(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int) -> Int
                  func many(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) -> Int
                  func throwingMany(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) throws -> Int
                  func rethrowingMany(_ operation: @escaping () throws -> Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) rethrows -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class CapabilityServiceMock: CapabilityService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                internal var given: __MockSynGiven {
                  __MockSynGiven(__mockSyn: __mockSyn)
                }

                internal var when: __MockSynGiven {
                  given
                }

                internal var verify: __MockSynVerify {
                  __MockSynVerify(__mockSyn: __mockSyn)
                }

                internal func confirmVerified() throws {
                  try __mockSyn.confirmVerified()
                }

                internal func checkUnnecessaryStubs() throws {
                  try __mockSyn.checkUnnecessaryStubs()
                }

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var title: MockSynNonThrowingPropertyStubber<String> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "title.get", setMember: "title.set")
                  }

                  internal var throwingTitle: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "throwingTitle.get", setMember: "throwingTitle.set")
                  }

                  internal func `subscript`(index: MockSynMatcher<Int>) -> MockSynNonThrowingSubscriptStubber<String> {
                    MockSynNonThrowingSubscriptStubber(runtime: __mockSyn, getMember: "subscript(index:).get", setMember: "subscript(index:).set", indexMatchers: [index.erase()])
                  }

                  internal func `subscript`(throwing index: MockSynMatcher<String>) -> MockSynSubscriptStubber<String> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(throwing:).get", setMember: "subscript(throwing:).set", indexMatchers: [index.erase()])
                  }

                  internal func three(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<String>, _ c: MockSynMatcher<Bool>) -> MockSynNonThrowingStubBuilder3<Int, String, Bool, String> {
                    MockSynNonThrowingStubBuilder3<Int, String, Bool, String>(runtime: __mockSyn, member: "three(_:_:_:)", matchers: [a.erase(), b.erase(), c.erase()])
                  }

                  internal func four(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>) -> MockSynStubBuilder4<Int, Int, Int, Int, Int> {
                    MockSynStubBuilder4<Int, Int, Int, Int, Int>(runtime: __mockSyn, member: "four(_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase()])
                  }

                  internal func five(_ operation: MockSynMatcher<() throws -> Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>) -> MockSynRethrowingStubBuilder5<() throws -> Int, Int, Int, Int, Int, Int> {
                    MockSynRethrowingStubBuilder5<() throws -> Int, Int, Int, Int, Int, Int>(runtime: __mockSyn, member: "five(_:_:_:_:_:)", matchers: [operation.erase(), b.erase(), c.erase(), d.erase(), e.erase()])
                  }

                  internal func six(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>) -> MockSynNonThrowingStubBuilder6<Int, Int, Int, Int, Int, Int, Int> {
                    MockSynNonThrowingStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(runtime: __mockSyn, member: "six(_:_:_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase()])
                  }

                  internal func many(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>, _ g: MockSynMatcher<Int>) -> MockSynNonThrowingStubBuilderReturnOnly<Int> {
                    MockSynNonThrowingStubBuilderReturnOnly<Int>(runtime: __mockSyn, member: "many(_:_:_:_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase(), g.erase()])
                  }

                  internal func throwingMany(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>, _ g: MockSynMatcher<Int>) -> MockSynStubBuilderReturnOnly<Int> {
                    MockSynStubBuilderReturnOnly<Int>(runtime: __mockSyn, member: "throwingMany(_:_:_:_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase(), g.erase()])
                  }

                  internal func rethrowingMany(_ operation: MockSynMatcher<() throws -> Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>, _ g: MockSynMatcher<Int>) -> MockSynRethrowingStubBuilderReturnOnly<Int> {
                    MockSynRethrowingStubBuilderReturnOnly<Int>(runtime: __mockSyn, member: "rethrowingMany(_:_:_:_:_:_:_:)", matchers: [operation.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase(), g.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var title: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "title.get", setMember: "title.set")
                  }

                  internal var throwingTitle: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "throwingTitle.get", setMember: "throwingTitle.set")
                  }

                  internal func `subscript`(index: MockSynMatcher<Int>) -> MockSynSubscriptVerification<String> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(index:).get", setMember: "subscript(index:).set", indexMatchers: [index.erase()])
                  }

                  internal func `subscript`(throwing index: MockSynMatcher<String>) -> MockSynSubscriptVerification<String> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(throwing:).get", setMember: "subscript(throwing:).set", indexMatchers: [index.erase()])
                  }

                  internal func three(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<String>, _ c: MockSynMatcher<Bool>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "three(_:_:_:)", matchers: [a.erase(), b.erase(), c.erase()])
                  }

                  internal func four(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "four(_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase()])
                  }

                  internal func five(_ operation: MockSynMatcher<() throws -> Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "five(_:_:_:_:_:)", matchers: [operation.erase(), b.erase(), c.erase(), d.erase(), e.erase()])
                  }

                  internal func six(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "six(_:_:_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase()])
                  }

                  internal func many(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>, _ g: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "many(_:_:_:_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase(), g.erase()])
                  }

                  internal func throwingMany(_ a: MockSynMatcher<Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>, _ g: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "throwingMany(_:_:_:_:_:_:_:)", matchers: [a.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase(), g.erase()])
                  }

                  internal func rethrowingMany(_ operation: MockSynMatcher<() throws -> Int>, _ b: MockSynMatcher<Int>, _ c: MockSynMatcher<Int>, _ d: MockSynMatcher<Int>, _ e: MockSynMatcher<Int>, _ f: MockSynMatcher<Int>, _ g: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "rethrowingMany(_:_:_:_:_:_:_:)", matchers: [operation.erase(), b.erase(), c.erase(), d.erase(), e.erase(), f.erase(), g.erase()])
                  }
                }

                internal var title: String {
                  get {
                    __mockSyn.resolve(member: "title.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "title.set", arguments: [newValue as Any])
                  }
                }

                internal var throwingTitle: String {
                  get throws {
                    try __mockSyn.resolveThrowing(member: "throwingTitle.get", arguments: [], returnType: String.self)
                  }
                }

                internal subscript(index: Int) -> String {
                  get {
                    __mockSyn.resolve(member: "subscript(index:).get", arguments: [index as Any], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "subscript(index:).set", arguments: [index as Any, newValue as Any])
                  }
                }

                internal subscript(throwing index: String) -> String {
                  get throws {
                    try __mockSyn.resolveThrowing(member: "subscript(throwing:).get", arguments: [index as Any], returnType: String.self)
                  }
                }

                internal func three(_ a: Int, _ b: String, _ c: Bool) -> String {
                  return __mockSyn.resolve(member: "three(_:_:_:)", arguments: [a as Any, b as Any, c as Any], returnType: String.self)
                }

                internal func four(_ a: Int, _ b: Int, _ c: Int, _ d: Int) throws -> Int {
                  return try __mockSyn.resolveThrowing(member: "four(_:_:_:_:)", arguments: [a as Any, b as Any, c as Any, d as Any], returnType: Int.self)
                }

                internal func five(_ operation: @escaping () throws -> Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int) rethrows -> Int {
                  return __mockSyn.resolve(member: "five(_:_:_:_:_:)", arguments: [operation as Any, b as Any, c as Any, d as Any, e as Any], returnType: Int.self)
                }

                internal func six(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int) -> Int {
                  return __mockSyn.resolve(member: "six(_:_:_:_:_:_:)", arguments: [a as Any, b as Any, c as Any, d as Any, e as Any, f as Any], returnType: Int.self)
                }

                internal func many(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) -> Int {
                  return __mockSyn.resolve(member: "many(_:_:_:_:_:_:_:)", arguments: [a as Any, b as Any, c as Any, d as Any, e as Any, f as Any, g as Any], returnType: Int.self)
                }

                internal func throwingMany(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) throws -> Int {
                  return try __mockSyn.resolveThrowing(member: "throwingMany(_:_:_:_:_:_:_:)", arguments: [a as Any, b as Any, c as Any, d as Any, e as Any, f as Any, g as Any], returnType: Int.self)
                }

                internal func rethrowingMany(_ operation: @escaping () throws -> Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) rethrows -> Int {
                  return __mockSyn.resolve(member: "rethrowingMany(_:_:_:_:_:_:_:)", arguments: [operation as Any, b as Any, c as Any, d as Any, e as Any, f as Any, g as Any], returnType: Int.self)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn typed willRun supports up to 6 parameters; 'many(_:_:_:_:_:_:_:)' has 7. Configure it with willReturn instead.",
                    line: 11,
                    column: 5,
                    severity: .warning
                ),
                DiagnosticSpec(
                    message: "MockSyn typed willRun supports up to 6 parameters; 'throwingMany(_:_:_:_:_:_:_:)' has 7. Configure it with willReturn or willThrow instead.",
                    line: 12,
                    column: 5,
                    severity: .warning
                ),
                DiagnosticSpec(
                    message: "MockSyn typed willRun supports up to 6 parameters; 'rethrowingMany(_:_:_:_:_:_:_:)' has 7. Configure it with willReturn instead.",
                    line: 13,
                    column: 5,
                    severity: .warning
                ),
            ]
        )
    }
}
