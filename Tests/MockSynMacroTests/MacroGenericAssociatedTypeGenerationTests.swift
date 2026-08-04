import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingGeneratesGenericClassDouble() {
        assertExpansion(
            """
            @Mocking
            class Box<Value> where Value: Sendable {
                func load(_ value: Value) -> Value {
                    value
                }
            }
            """,
            expandedSource: """
              class Box<Value> where Value: Sendable {
                  func load(_ value: Value) -> Value {
                      value
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class BoxMock<Value>: Box<Value> where Value: Sendable {
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

                  internal func load(_ value: MockSynMatcher<Value>) -> MockSynNonThrowingStubBuilder1<Value, Value> {
                    MockSynNonThrowingStubBuilder1<Value, Value>(runtime: __mockSyn, member: "load(_:)", matchers: [value.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load(_ value: MockSynMatcher<Value>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(_:)", matchers: [value.erase()])
                  }
                }

                internal override func load(_ value: Value) -> Value {
                  return __mockSyn.resolve(member: "load(_:)", arguments: [value as Any], returnType: Value.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesGenericMockForAssociatedTypeProtocol() {
        assertExpansion(
            """
            @Mocking
            protocol Repository {
                associatedtype Entity
                func load() -> Entity
            }
            """,
            expandedSource: """
              protocol Repository {
                  associatedtype Entity
                  func load() -> Entity
              }

              #if MOCKSYN_ENABLE
              internal final class RepositoryMock<Entity>: Repository {
                internal typealias Entity = Entity
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

                  internal func load() -> MockSynNonThrowingStubBuilder<Entity> {
                    MockSynNonThrowingStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal func load() -> Entity {
                  return __mockSyn.resolve(member: "load()", arguments: [], returnType: Entity.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingPreservesAssociatedTypeConstraints() {
        assertExpansion(
            """
            @Mocking
            protocol Repository {
                associatedtype ID: Hashable
                associatedtype Entity: Sendable where Entity: Equatable
                func load(id: ID) -> Entity
            }
            """,
            expandedSource: """
              protocol Repository {
                  associatedtype ID: Hashable
                  associatedtype Entity: Sendable where Entity: Equatable
                  func load(id: ID) -> Entity
              }

              #if MOCKSYN_ENABLE
              internal final class RepositoryMock<ID: Hashable, Entity: Sendable>: Repository where Entity: Equatable {
                internal typealias ID = ID
                internal typealias Entity = Entity
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

                  internal func load(id: MockSynMatcher<ID>) -> MockSynNonThrowingStubBuilder1<ID, Entity> {
                    MockSynNonThrowingStubBuilder1<ID, Entity>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load(id: MockSynMatcher<ID>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }
                }

                internal func load(id: ID) -> Entity {
                  return __mockSyn.resolve(member: "load(id:)", arguments: [id as Any], returnType: Entity.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingUsesFileprivateAssociatedTypeWitnessForPrivateProtocol() {
        assertExpansion(
            """
            @Mocking(access: .private)
            private protocol Repository {
                associatedtype Entity
                func load() -> Entity
            }
            """,
            expandedSource: """
              private protocol Repository {
                  associatedtype Entity
                  func load() -> Entity
              }

              #if MOCKSYN_ENABLE
              private final class RepositoryMock<Entity>: Repository {
                fileprivate typealias Entity = Entity
                fileprivate let __mockSyn: MockSynRuntime

                fileprivate init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                fileprivate var given: __MockSynGiven {
                  __MockSynGiven(__mockSyn: __mockSyn)
                }

                fileprivate var when: __MockSynGiven {
                  given
                }

                fileprivate var verify: __MockSynVerify {
                  __MockSynVerify(__mockSyn: __mockSyn)
                }

                fileprivate func confirmVerified() throws {
                  try __mockSyn.confirmVerified()
                }

                fileprivate func checkUnnecessaryStubs() throws {
                  try __mockSyn.checkUnnecessaryStubs()
                }

                fileprivate func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                fileprivate struct __MockSynGiven {
                  fileprivate let __mockSyn: MockSynRuntime

                  fileprivate func load() -> MockSynNonThrowingStubBuilder<Entity> {
                    MockSynNonThrowingStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                fileprivate struct __MockSynVerify {
                  fileprivate let __mockSyn: MockSynRuntime

                  fileprivate func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                fileprivate func load() -> Entity {
                  return __mockSyn.resolve(member: "load()", arguments: [], returnType: Entity.self)
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesGenericSpyForAssociatedTypeProtocol() {
        assertExpansion(
            """
            @Spying
            protocol Repository {
                associatedtype Entity
                func load() -> Entity
            }
            """,
            expandedSource: """
              protocol Repository {
                  associatedtype Entity
                  func load() -> Entity
              }

              #if MOCKSYN_ENABLE
              internal final class RepositorySpy<Entity, __MockSynWrapped: Repository>: Repository where __MockSynWrapped.Entity == Entity {
                internal typealias Entity = Entity
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: __MockSynWrapped

                internal init(wrapping __mockSynWrapped: __MockSynWrapped, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
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

                  internal func load() -> MockSynNonThrowingStubBuilder<Entity> {
                    MockSynNonThrowingStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal func load() -> Entity {
                  return __mockSyn.resolve(member: "load()", arguments: [], returnType: Entity.self, fallback: {
                      self.__mockSynWrapped.load()
                    })
                }
              }
              #endif
              """
        )
    }

    func testMockingSupportsQualifiedProtocolInheritance() {
        assertExpansion(
            """
            @Mocking
            protocol UserService: Foundation.Sendable {
            }
            """,
            expandedSource: """
              protocol UserService: Foundation.Sendable {
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
}
