import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testReadOnlyClassPropertyGetterContainingDatasetHasNoSetterCapability() {
        assertExpansion(
            """
            @Mocking
            class DatasetPropertyService {
                var name: String { get { dataset } }
            }
            """,
            expandedSource: """
              class DatasetPropertyService {
                  var name: String { get { dataset } }
              }

              #if MOCKSYN_ENABLE
              internal final class DatasetPropertyServiceMock: DatasetPropertyService {
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

                  internal var name: MockSynNonThrowingReadOnlyPropertyStubber<String> {
                    MockSynNonThrowingReadOnlyPropertyStubber(runtime: __mockSyn, getMember: "name.get")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var name: MockSynReadOnlyPropertyVerification<String> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "name.get")
                  }
                }

                internal override var name: String {
                  get {
                    __mockSyn.resolve(member: "name.get", arguments: [], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testReadOnlyClassSubscriptGetterContainingDatasetHasNoSetterCapability() {
        assertExpansion(
            """
            @Mocking
            class DatasetSubscriptService {
                subscript(index: Int) -> String { get { dataset[index] } }
            }
            """,
            expandedSource: """
              class DatasetSubscriptService {
                  subscript(index: Int) -> String { get { dataset[index] } }
              }

              #if MOCKSYN_ENABLE
              internal final class DatasetSubscriptServiceMock: DatasetSubscriptService {
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

                  internal func `subscript`(index: MockSynMatcher<Int>) -> MockSynNonThrowingReadOnlySubscriptStubber<String> {
                    MockSynNonThrowingReadOnlySubscriptStubber(runtime: __mockSyn, getMember: "subscript(index:).get", indexMatchers: [index.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func `subscript`(index: MockSynMatcher<Int>) -> MockSynReadOnlySubscriptVerification<String> {
                    MockSynReadOnlySubscriptVerification(runtime: __mockSyn, getMember: "subscript(index:).get", indexMatchers: [index.erase()])
                  }
                }

                internal override subscript(index: Int) -> String {
                  get {
                    __mockSyn.resolve(member: "subscript(index:).get", arguments: [index as Any], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testModifyAccessorsRetainSetterCapability() {
        assertExpansion(
            """
            @Mocking
            class ModifyAccessorService {
                var value: String {
                    get { dataset }
                    _modify { yield &dataset }
                }

                subscript(index: Int) -> String {
                    get { dataset[index] }
                    _modify { yield &dataset[index] }
                }
            }
            """,
            expandedSource: """
              class ModifyAccessorService {
                  var value: String {
                      get { dataset }
                      _modify { yield &dataset }
                  }

                  subscript(index: Int) -> String {
                      get { dataset[index] }
                      _modify { yield &dataset[index] }
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class ModifyAccessorServiceMock: ModifyAccessorService {
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

                  internal var value: MockSynNonThrowingPropertyStubber<String> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "value.get", setMember: "value.set")
                  }

                  internal func `subscript`(index: MockSynMatcher<Int>) -> MockSynNonThrowingSubscriptStubber<String> {
                    MockSynNonThrowingSubscriptStubber(runtime: __mockSyn, getMember: "subscript(index:).get", setMember: "subscript(index:).set", indexMatchers: [index.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var value: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "value.get", setMember: "value.set")
                  }

                  internal func `subscript`(index: MockSynMatcher<Int>) -> MockSynSubscriptVerification<String> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(index:).get", setMember: "subscript(index:).set", indexMatchers: [index.erase()])
                  }
                }

                internal override var value: String {
                  get {
                    __mockSyn.resolve(member: "value.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "value.set", arguments: [newValue as Any])
                  }
                }

                internal override subscript(index: Int) -> String {
                  get {
                    __mockSyn.resolve(member: "subscript(index:).get", arguments: [index as Any], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "subscript(index:).set", arguments: [index as Any, newValue as Any])
                  }
                }
              }
              #endif
              """
        )
    }

    func testObservedClassPropertiesRetainSetterCapability() {
        assertExpansion(
            """
            @Mocking
            class ObservedPropertyService {
                var willSetValue: String = "initial" {
                    willSet { }
                }

                var didSetValue: String = "initial" {
                    didSet { }
                }
            }
            """,
            expandedSource: """
              class ObservedPropertyService {
                  var willSetValue: String = "initial" {
                      willSet { }
                  }

                  var didSetValue: String = "initial" {
                      didSet { }
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class ObservedPropertyServiceMock: ObservedPropertyService {
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

                  internal var willSetValue: MockSynNonThrowingPropertyStubber<String> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "willSetValue.get", setMember: "willSetValue.set")
                  }

                  internal var didSetValue: MockSynNonThrowingPropertyStubber<String> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "didSetValue.get", setMember: "didSetValue.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var willSetValue: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "willSetValue.get", setMember: "willSetValue.set")
                  }

                  internal var didSetValue: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "didSetValue.get", setMember: "didSetValue.set")
                  }
                }

                internal override var willSetValue: String {
                  get {
                    __mockSyn.resolve(member: "willSetValue.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "willSetValue.set", arguments: [newValue as Any])
                  }
                }

                internal override var didSetValue: String {
                  get {
                    __mockSyn.resolve(member: "didSetValue.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "didSetValue.set", arguments: [newValue as Any])
                  }
                }
              }
              #endif
              """
        )
    }
}
