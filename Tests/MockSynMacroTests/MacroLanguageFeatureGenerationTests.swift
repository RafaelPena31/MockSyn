import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testSpyingGeneratesDelegatingEffectfulPropertyAccessors() {
        assertExpansion(
            """
            @Spying
            protocol EffectfulPropertyService {
                var asyncName: String { get async }
                var asyncThrowingName: String { get async throws }
            }
            """,
            expandedSource: """
              protocol EffectfulPropertyService {
                  var asyncName: String { get async }
                  var asyncThrowingName: String { get async throws }
              }

              #if MOCKSYN_ENABLE
              internal final class EffectfulPropertyServiceSpy: EffectfulPropertyService {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any EffectfulPropertyService

                internal init(wrapping __mockSynWrapped: any EffectfulPropertyService, mode: MockSynMode = .strict) {
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

                  internal var asyncName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncName.get", setMember: "asyncName.set")
                  }

                  internal var asyncThrowingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncThrowingName.get", setMember: "asyncThrowingName.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var asyncName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "asyncName.get", setMember: "asyncName.set")
                  }

                  internal var asyncThrowingName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "asyncThrowingName.get", setMember: "asyncThrowingName.set")
                  }
                }

                internal var asyncName: String {
                  get async {
                    __mockSyn.record(member: "asyncName.get", arguments: [])
                    return await self.__mockSynWrapped.asyncName
                  }
                }

                internal var asyncThrowingName: String {
                  get async throws {
                    __mockSyn.record(member: "asyncThrowingName.get", arguments: [])
                    return try await self.__mockSynWrapped.asyncThrowingName
                  }
                }
              }
              #endif
              """
        )
    }

    func testMockingPreservesSwiftLanguageFeatureMembers() {
        assertExpansion(
            """
            @Mocking
            protocol Processor: Sendable {
                @MainActor var title: String { get }
                func map<Value>(_ value: Value) -> Value where Value: Sendable
                func update(_ value: inout Int)
                func handle(_ action: @escaping (String) -> Void)
                func clone() -> Self
                func collect(_ values: Int...) -> Int
            }
            """,
            expandedSource: """
              protocol Processor: Sendable {
                  @MainActor var title: String { get }
                  func map<Value>(_ value: Value) -> Value where Value: Sendable
                  func update(_ value: inout Int)
                  func handle(_ action: @escaping (String) -> Void)
                  func clone() -> Self
                  func collect(_ values: Int...) -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class ProcessorMock: Processor {
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

                  internal var title: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "title.get", setMember: "title.set")
                  }

                  internal func map<Value>(_ value: MockSynMatcher<Value>) -> MockSynStubBuilder1<Value, Value> where Value: Sendable {
                    MockSynStubBuilder1<Value, Value>(runtime: __mockSyn, member: "map(_:)", matchers: [value.erase()])
                  }

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynStubBuilder1<Int, Void> {
                    MockSynStubBuilder1<Int, Void>(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynStubBuilder1<(String) -> Void, Void> {
                    MockSynStubBuilder1<(String) -> Void, Void>(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func clone() -> MockSynStubBuilder<ProcessorMock> {
                    MockSynStubBuilder<ProcessorMock>(runtime: __mockSyn, member: "clone()", matchers: [])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynStubBuilder1<[Int], Int> {
                    MockSynStubBuilder1<[Int], Int>(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var title: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "title.get", setMember: "title.set")
                  }

                  internal func map<Value>(_ value: MockSynMatcher<Value>) -> MockSynVerification where Value: Sendable {
                    MockSynVerification(runtime: __mockSyn, member: "map(_:)", matchers: [value.erase()])
                  }

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func clone() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "clone()", matchers: [])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                @MainActor internal var title: String {
                  get {
                    __mockSyn.resolve(member: "title.get", arguments: [], returnType: String.self)
                  }
                }

                internal func map<Value>(_ value: Value) -> Value where Value: Sendable {
                  return __mockSyn.resolve(member: "map(_:)", arguments: [value as Any], returnType: Value.self)
                }

                internal func update(_ value: inout Int) {
                  __mockSyn.resolveVoid(member: "update(_:)", arguments: [value as Any])
                }

                internal func handle(_ action: @escaping (String) -> Void) {
                  __mockSyn.resolveVoid(member: "handle(_:)", arguments: [action as Any])
                }

                internal func clone() -> Self {
                  return __mockSyn.resolve(member: "clone()", arguments: [], returnType: Self.self)
                }

                internal func collect(_ values: Int...) -> Int {
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self)
                }
              }
              #endif
              """
        )
    }

    func testSpyingDelegatesSupportedSwiftLanguageFeatureMembers() {
        assertExpansion(
            """
            @Spying
            protocol Processor {
                func update(_ value: inout Int)
                func handle(_ action: @escaping (String) -> Void)
                func collect(_ values: Int...) -> Int
            }
            """,
            expandedSource: """
              protocol Processor {
                  func update(_ value: inout Int)
                  func handle(_ action: @escaping (String) -> Void)
                  func collect(_ values: Int...) -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class ProcessorSpy: Processor {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any Processor

                internal init(wrapping __mockSynWrapped: any Processor, mode: MockSynMode = .strict) {
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

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynStubBuilder1<Int, Void> {
                    MockSynStubBuilder1<Int, Void>(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynStubBuilder1<(String) -> Void, Void> {
                    MockSynStubBuilder1<(String) -> Void, Void>(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynStubBuilder1<[Int], Int> {
                    MockSynStubBuilder1<[Int], Int>(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal func update(_ value: inout Int) {
                  __mockSyn.record(member: "update(_:)", arguments: [value as Any])
                  __mockSynWrapped.update(&value)
                }

                internal func handle(_ action: @escaping (String) -> Void) {
                  __mockSyn.resolveVoid(member: "handle(_:)", arguments: [action as Any], fallback: {
                      self.__mockSynWrapped.handle(action)
                    })
                }

                internal func collect(_ values: Int...) -> Int {
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self, fallback: {
                        switch values.count {
                    case 0:
                      return self.__mockSynWrapped.collect()
                    case 1:
                      return self.__mockSynWrapped.collect(values[0])
                    case 2:
                      return self.__mockSynWrapped.collect(values[0], values[1])
                    case 3:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2])
                    case 4:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3])
                    case 5:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4])
                    case 6:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4], values[5])
                    case 7:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4], values[5], values[6])
                    case 8:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7])
                        default:
                          fatalError("MockSyn spy cannot delegate variadic member collect(_:) with more than 8 values")
                        }
                  })
                }
              }
              #endif
              """
        )
    }
}
