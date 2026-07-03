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

                  internal func load(_ value: MockSynMatcher<Value>) -> MockSynStubBuilder1<Value, Value> {
                    MockSynStubBuilder1<Value, Value>(runtime: __mockSyn, member: "load(_:)", matchers: [value.erase()])
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

                  internal func load() -> MockSynStubBuilder<Entity> {
                    MockSynStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
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

                  internal func load(id: MockSynMatcher<ID>) -> MockSynStubBuilder1<ID, Entity> {
                    MockSynStubBuilder1<ID, Entity>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
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
                private let __mockSyn: MockSynRuntime

                private init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                private var given: __MockSynGiven {
                  __MockSynGiven(__mockSyn: __mockSyn)
                }

                private var when: __MockSynGiven {
                  given
                }

                private var verify: __MockSynVerify {
                  __MockSynVerify(__mockSyn: __mockSyn)
                }

                private func confirmVerified() throws {
                  try __mockSyn.confirmVerified()
                }

                private func checkUnnecessaryStubs() throws {
                  try __mockSyn.checkUnnecessaryStubs()
                }

                private func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                private struct __MockSynGiven {
                  private let __mockSyn: MockSynRuntime

                  private func load() -> MockSynStubBuilder<Entity> {
                    MockSynStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                private struct __MockSynVerify {
                  private let __mockSyn: MockSynRuntime

                  private func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                private func load() -> Entity {
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

                  internal func load() -> MockSynStubBuilder<Entity> {
                    MockSynStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
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
