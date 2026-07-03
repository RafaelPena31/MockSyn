import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MockSynMacros)
@testable import MockSynMacros
#endif

extension MockSynMacroTests {
    func testPluginProvidesBlockOneMacros() {
        #if canImport(MockSynMacros)
        let plugin = MockSynPlugin()

        XCTAssertEqual(plugin.providingMacros.count, 3)
        XCTAssertTrue(plugin.providingMacros.contains { $0 == MockingMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == StubbingMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == SpyingMacro.self })
        #endif
    }

    func testMockingGeneratesInternalStrictMockByDefault() {
        assertExpansion(
            """
            @Mocking
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesPackageAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .package)
            package protocol UserService {
            }
            """,
            expandedSource: """
              package protocol UserService {
              }

              #if MOCKSYN_ENABLE
              package final class UserServiceMock: UserService {
                package let __mockSyn: MockSynRuntime

                package init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesFileprivateAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .fileprivate)
            fileprivate protocol UserService {
            }
            """,
            expandedSource: """
              fileprivate protocol UserService {
              }

              #if MOCKSYN_ENABLE
              fileprivate final class UserServiceMock: UserService {
                fileprivate let __mockSyn: MockSynRuntime

                fileprivate init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesPrivateAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .private)
            private protocol UserService {
            }
            """,
            expandedSource: """
              private protocol UserService {
              }

              #if MOCKSYN_ENABLE
              private final class UserServiceMock: UserService {
                private let __mockSyn: MockSynRuntime

                private init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testStubbingGeneratesInternalRelaxedStubByDefault() {
        assertExpansion(
            """
            @Stubbing
            protocol AnalyticsService {
            }
            """,
            expandedSource: """
              protocol AnalyticsService {
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesInternalStrictSpyWithWrappedImplementation() {
        assertExpansion(
            """
            @Spying
            protocol CacheStore {
            }
            """,
            expandedSource: """
              protocol CacheStore {
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any CacheStore

                internal init(wrapping __mockSynWrapped: any CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                }
              }
              #endif
              """
        )
    }

    func testMockingUsesCustomNameAccessAndMode() {
        assertExpansion(
            """
            @Mocking(name: "MockUserService", access: .public, mode: .relaxed)
            public protocol UserService {
            }
            """,
            expandedSource: """
              public protocol UserService {
              }

              #if MOCKSYN_ENABLE
              public final class MockUserService: UserService {
                public let __mockSyn: MockSynRuntime

                public init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }
}
