extension MockSynMacroTests {
    func testPublicClassImplicitInitializerRemainsInternal() {
        assertExpansion(
            """
            @Mocking
            public class UserService {
            }
            """,
            expandedSource: """
              public class UserService {
              }

              #if MOCKSYN_ENABLE
              public final class UserServiceMock: UserService {
                public let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testPublicClassPreservesMethodAccessThroughReturnDisambiguation() {
        assertExpansion(
            """
            struct HiddenValue {
            }

            @Mocking
            public class UserService {
                func load() -> HiddenValue {
                    HiddenValue()
                }

                public func load() -> String {
                    "base"
                }
            }
            """,
            expandedSource: """
              struct HiddenValue {
              }
              public class UserService {
                  func load() -> HiddenValue {
                      HiddenValue()
                  }

                  public func load() -> String {
                      "base"
                  }
              }

              #if MOCKSYN_ENABLE
              public final class UserServiceMock: UserService {
                public let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
                public var given: __MockSynGiven {
                  __MockSynGiven(__mockSyn: __mockSyn)
                }

                public var when: __MockSynGiven {
                  given
                }

                public var verify: __MockSynVerify {
                  __MockSynVerify(__mockSyn: __mockSyn)
                }

                public func confirmVerified() throws {
                  try __mockSyn.confirmVerified()
                }

                public func checkUnnecessaryStubs() throws {
                  try __mockSyn.checkUnnecessaryStubs()
                }

                public func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                public struct __MockSynGiven {
                  public let __mockSyn: MockSynRuntime

                  internal func loadReturningHiddenValue() -> MockSynNonThrowingStubBuilder<HiddenValue> {
                    MockSynNonThrowingStubBuilder<HiddenValue>(runtime: __mockSyn, member: "load() -> HiddenValue", matchers: [])
                  }

                  public func loadReturningString() -> MockSynNonThrowingStubBuilder<String> {
                    MockSynNonThrowingStubBuilder<String>(runtime: __mockSyn, member: "load() -> String", matchers: [])
                  }
                }

                public struct __MockSynVerify {
                  public let __mockSyn: MockSynRuntime

                  internal func loadReturningHiddenValue() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load() -> HiddenValue", matchers: [])
                  }

                  public func loadReturningString() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load() -> String", matchers: [])
                  }
                }

                internal override func load() -> HiddenValue {
                  return __mockSyn.resolve(member: "load() -> HiddenValue", arguments: [], returnType: HiddenValue.self)
                }

                public override func load() -> String {
                  return __mockSyn.resolve(member: "load() -> String", arguments: [], returnType: String.self)
                }
              }
              #endif
              """
        )
    }
}
