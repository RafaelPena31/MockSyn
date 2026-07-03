import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingGeneratesSupportedClassMemberOverrides() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                var storedToken: String = "real"

                var token: String {
                    get { "real" }
                    set { }
                }

                func load(id: String) -> String {
                    "real"
                }

                func save(_ user: String) throws {
                }

                subscript(key: String) -> String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class UserService {
                  var storedToken: String = "real"

                  var token: String {
                      get { "real" }
                      set { }
                  }

                  func load(id: String) -> String {
                      "real"
                  }

                  func save(_ user: String) throws {
                  }

                  subscript(key: String) -> String {
                      "real"
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
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

                  internal var storedToken: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "storedToken.get", setMember: "storedToken.set")
                  }

                  internal var token: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, String> {
                    MockSynStubBuilder1<String, String>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func save(_ user: MockSynMatcher<String>) -> MockSynStubBuilder1<String, Void> {
                    MockSynStubBuilder1<String, Void>(runtime: __mockSyn, member: "save(_:)", matchers: [user.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptStubber<String> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var storedToken: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "storedToken.get", setMember: "storedToken.set")
                  }

                  internal var token: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func save(_ user: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "save(_:)", matchers: [user.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptVerification<String> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }
                }

                internal override var storedToken: String {
                  get {
                    __mockSyn.resolve(member: "storedToken.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "storedToken.set", arguments: [newValue as Any])
                  }
                }

                internal override var token: String {
                  get {
                    __mockSyn.resolve(member: "token.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "token.set", arguments: [newValue as Any])
                  }
                }

                internal override func load(id: String) -> String {
                  return __mockSyn.resolve(member: "load(id:)", arguments: [id as Any], returnType: String.self)
                }

                internal override func save(_ user: String) throws {
                  try __mockSyn.resolveVoidThrowing(member: "save(_:)", arguments: [user as Any])
                }

                internal override subscript(key: String) -> String {
                  get {
                    __mockSyn.resolve(member: "subscript(key:).get", arguments: [key as Any], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testPropertyWithoutExplicitTypeIsIgnored() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                var inferred = "value"
            }
            """,
            expandedSource: """
              class UserService {
                  var inferred = "value"
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testClassComputedGetterShorthandGeneratesOverride() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                var displayName: String { "base" }
            }
            """,
            expandedSource: """
              class UserService {
                  var displayName: String { "base" }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
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

                  internal var displayName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "displayName.get", setMember: "displayName.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var displayName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "displayName.get", setMember: "displayName.set")
                  }
                }

                internal override var displayName: String {
                  get {
                    __mockSyn.resolve(member: "displayName.get", arguments: [], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testOperatorRequirementsGenerateStaticOperatorAndNamedDsl() {
        assertExpansion(
            """
            @Mocking
            protocol ComparableService {
                static func == (lhs: Self, rhs: Self) -> Bool
                static func + (lhs: Self, rhs: Self) -> Self
                static func <~> (lhs: Self, rhs: Self) -> Bool
            }
            """,
            expandedSource: """
              protocol ComparableService {
                  static func == (lhs: Self, rhs: Self) -> Bool
                  static func + (lhs: Self, rhs: Self) -> Self
                  static func <~> (lhs: Self, rhs: Self) -> Bool
              }

              #if MOCKSYN_ENABLE
              internal final class ComparableServiceMock: ComparableService {
                internal static let __mockSynStatic = MockSynRuntime(kind: .mock, mode: .strict)
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                internal static var given: __MockSynStaticGiven {
                  __MockSynStaticGiven(__mockSyn: __mockSynStatic)
                }

                internal static var when: __MockSynStaticGiven {
                  given
                }

                internal static var verify: __MockSynStaticVerify {
                  __MockSynStaticVerify(__mockSyn: __mockSynStatic)
                }

                internal static func confirmStaticVerified() throws {
                  try __mockSynStatic.confirmVerified()
                }

                internal static func checkUnnecessaryStaticStubs() throws {
                  try __mockSynStatic.checkUnnecessaryStubs()
                }

                internal static func resetStatic(_ scope: MockSynResetScope = .all) {
                  __mockSynStatic.reset(scope)
                }

                internal struct __MockSynStaticGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func equalTo(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool> {
                    MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool>(runtime: __mockSyn, member: "==(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func plus(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, ComparableServiceMock> {
                    MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, ComparableServiceMock>(runtime: __mockSyn, member: "+(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func operator_u3c_u7e_u3e(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool> {
                    MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool>(runtime: __mockSyn, member: "<~>(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func equalTo(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "==(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func plus(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "+(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func operator_u3c_u7e_u3e(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "<~>(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }
                }

                internal static func == (lhs: ComparableServiceMock, rhs: ComparableServiceMock) -> Bool {
                  return __mockSynStatic.resolve(member: "==(lhs:rhs:)", arguments: [lhs as Any, rhs as Any], returnType: Bool.self)
                }

                internal static func + (lhs: ComparableServiceMock, rhs: ComparableServiceMock) -> Self {
                  return __mockSynStatic.resolve(member: "+(lhs:rhs:)", arguments: [lhs as Any, rhs as Any], returnType: Self.self)
                }

                internal static func <~> (lhs: ComparableServiceMock, rhs: ComparableServiceMock) -> Bool {
                  return __mockSynStatic.resolve(member: "<~>(lhs:rhs:)", arguments: [lhs as Any, rhs as Any], returnType: Bool.self)
                }
              }
              #endif
              """
        )
    }
}
