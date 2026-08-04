import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingSupportsSimpleProtocolInheritance() {
        assertExpansion(
            """
            protocol UserService {
            }

            @Mocking
            protocol AdminUserService: UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              protocol AdminUserService: UserService {
              }

              #if MOCKSYN_ENABLE
              internal final class AdminUserServiceMock: AdminUserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mocking does not generate requirements inherited from UserService. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 4,
                    column: 1,
                    severity: .warning
                )
            ]
        )
    }

    func testMockingGeneratesSubclassForNonFinalClass() {
        assertExpansion(
            """
            @Mocking
            class UserService {
            }
            """,
            expandedSource: """
              class UserService {
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

    func testMockingMirrorsClassInitializerParameters() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(seed: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init(seed: seed)
                }
              }
              #endif
              """
        )
    }

    func testMockingMirrorsExplicitZeroArgumentClassInitializer() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init() {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init() {
                  }
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

    func testMockingMirrorsRequiredClassInitializerWithConfigurableConvenience() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                required init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  required init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal required init(seed: String) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: .strict)
                  super.init(seed: seed)
                }

                internal init(seed: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init(seed: seed)
                }
              }
              #endif
              """
        )
    }

    func testStubbingGeneratesSubclassForNonFinalClass() {
        assertExpansion(
            """
            @Stubbing
            class AnalyticsService {
            }
            """,
            expandedSource: """
              class AnalyticsService {
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testStubbingMirrorsClassInitializerParameters() {
        assertExpansion(
            """
            @Stubbing
            class AnalyticsService {
                init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class AnalyticsService {
                  init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(seed: String, mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                  super.init(seed: seed)
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesSubclassForNonFinalClassWithWrappedImplementation() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
            }
            """,
            expandedSource: """
              class CacheStore {
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: CacheStore

                internal init(wrapping __mockSynWrapped: CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testSpyingMirrorsClassInitializerParameters() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
                init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class CacheStore {
                  init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: CacheStore

                internal init(wrapping __mockSynWrapped: CacheStore, seed: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                  super.init(seed: seed)
                }
              }
              #endif
              """
        )
    }

    func testSpyingMirrorsExplicitZeroArgumentClassInitializer() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
                init() {
                }
            }
            """,
            expandedSource: """
              class CacheStore {
                  init() {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: CacheStore

                internal init(wrapping __mockSynWrapped: CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testSpyingOnClassWithRequiredInitializerEmitsDiagnostic() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
                required init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class CacheStore {
                  required init(seed: String) {
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mirror required class initializers for spies because class spies need a wrapped instance. Prefer a protocol spy or remove the required initializer.",
                    line: 1,
                    column: 1
                )
            ]
        )
    }

    func testMockingClassWithVariadicInitializerEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init(values: Int...) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init(values: Int...) {
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mirror variadic class initializers because Swift cannot forward captured variadic arrays to super.init.",
                    line: 1,
                    column: 1
                )
            ]
        )
    }

    func testMockingGeneratesSubclassForNSObjectBackedClass() {
        assertExpansion(
            """
            @Mocking
            @objcMembers
            class LegacyService: NSObject {
            }
            """,
            expandedSource: """
              @objcMembers
              class LegacyService: NSObject {
              }

              #if MOCKSYN_ENABLE
              internal final class LegacyServiceMock: LegacyService {
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

    func testMockingTreatsOpenClassAsPublicDeclaration() {
        assertExpansion(
            """
            @Mocking(access: .public)
            open class UserService {
            }
            """,
            expandedSource: """
              open class UserService {
              }

              #if MOCKSYN_ENABLE
              public final class UserServiceMock: UserService {
                public let __mockSyn: MockSynRuntime

                public init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testMockingInheritsPublicAccessFromClassByDefault() {
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

                public init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }
}
