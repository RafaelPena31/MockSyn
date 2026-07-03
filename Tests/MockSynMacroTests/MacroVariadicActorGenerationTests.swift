import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testSpyingDelegatesLabeledVariadicVoidMembers() {
        assertExpansion(
            """
            @Spying
            protocol Recorder {
                func record(_ prefix: String, suffix: String, values: Int...)
            }
            """,
            expandedSource: """
              protocol Recorder {
                  func record(_ prefix: String, suffix: String, values: Int...)
              }

              #if MOCKSYN_ENABLE
              internal final class RecorderSpy: Recorder {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any Recorder

                internal init(wrapping __mockSynWrapped: any Recorder, mode: MockSynMode = .strict) {
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

                  internal func record(_ prefix: MockSynMatcher<String>, suffix: MockSynMatcher<String>, values: MockSynMatcher<[Int]>) -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "record(_:suffix:values:)", matchers: [prefix.erase(), suffix.erase(), values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func record(_ prefix: MockSynMatcher<String>, suffix: MockSynMatcher<String>, values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "record(_:suffix:values:)", matchers: [prefix.erase(), suffix.erase(), values.erase()])
                  }
                }

                internal func record(_ prefix: String, suffix: String, values: Int...) {
                  __mockSyn.resolveVoid(member: "record(_:suffix:values:)", arguments: [prefix as Any, suffix as Any, values as Any], fallback: {
                        switch values.count {
                    case 0:
                      self.__mockSynWrapped.record(prefix, suffix: suffix)
                    case 1:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0])
                    case 2:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1])
                    case 3:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2])
                    case 4:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3])
                    case 5:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4])
                    case 6:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4], values[5])
                    case 7:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4], values[5], values[6])
                    case 8:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7])
                        default:
                          fatalError("MockSyn spy cannot delegate variadic member record(_:suffix:values:) with more than 8 values")
                        }
                  })
                }
              }
              #endif
              """
        )
    }

    func testSpyingLeavesAsyncVariadicMembersStubDriven() {
        assertExpansion(
            """
            @Spying
            protocol AsyncCollector {
                func collect(_ values: Int...) async -> Int
            }
            """,
            expandedSource: """
              protocol AsyncCollector {
                  func collect(_ values: Int...) async -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class AsyncCollectorSpy: AsyncCollector {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any AsyncCollector

                internal init(wrapping __mockSynWrapped: any AsyncCollector, mode: MockSynMode = .strict) {
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

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynStubBuilder1<[Int], Int> {
                    MockSynStubBuilder1<[Int], Int>(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal func collect(_ values: Int...) async -> Int {
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self)
                }
              }
              #endif
              """
        )
    }

    func testSpyingLeavesMultipleVariadicMembersStubDriven() {
        assertExpansion(
            """
            @Spying
            protocol MultiCollector {
                func collect(_ values: Int..., labels: String...) -> String
            }
            """,
            expandedSource: """
              protocol MultiCollector {
                  func collect(_ values: Int..., labels: String...) -> String
              }

              #if MOCKSYN_ENABLE
              internal final class MultiCollectorSpy: MultiCollector {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any MultiCollector

                internal init(wrapping __mockSynWrapped: any MultiCollector, mode: MockSynMode = .strict) {
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

                  internal func collect(_ values: MockSynMatcher<[Int]>, labels: MockSynMatcher<[String]>) -> MockSynStubBuilder2<[Int], [String], String> {
                    MockSynStubBuilder2<[Int], [String], String>(runtime: __mockSyn, member: "collect(_:labels:)", matchers: [values.erase(), labels.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func collect(_ values: MockSynMatcher<[Int]>, labels: MockSynMatcher<[String]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:labels:)", matchers: [values.erase(), labels.erase()])
                  }
                }

                internal func collect(_ values: Int..., labels: String...) -> String {
                  return __mockSyn.resolve(member: "collect(_:labels:)", arguments: [values as Any, labels as Any], returnType: String.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingPreservesGlobalActorOnType() {
        assertExpansion(
            """
            @Mocking
            @MainActor
            protocol MainService {
                func refresh()
            }
            """,
            expandedSource: """
              @MainActor
              protocol MainService {
                  func refresh()
              }

              #if MOCKSYN_ENABLE
              @MainActor internal final class MainServiceMock: MainService {
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

                  internal func refresh() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func refresh() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }
                }

                internal func refresh() {
                  __mockSyn.resolveVoid(member: "refresh()", arguments: [])
                }
              }
              #endif
              """
        )
    }
}
