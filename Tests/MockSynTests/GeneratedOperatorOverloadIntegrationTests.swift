import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
    func testGeneratedOperatorRequirementsSupportStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        OperatorComparableServiceMock.resetStatic()
        let lhs = OperatorComparableServiceMock()
        let rhs = OperatorComparableServiceMock()

        OperatorComparableServiceMock.given.equalTo(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).willReturn(true)
        OperatorComparableServiceMock.given.plus(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).willReturn(lhs)

        XCTAssertTrue(lhs == rhs)
        XCTAssertTrue((lhs + rhs) === lhs)

        try OperatorComparableServiceMock.verify.equalTo(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).once()
        try OperatorComparableServiceMock.verify.plus(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).once()
        try OperatorComparableServiceMock.confirmStaticVerified()
        try OperatorComparableServiceMock.checkUnnecessaryStaticStubs()
        OperatorComparableServiceMock.resetStatic()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedReturnTypeOverloadsUseReturnDisambiguatedDslAndRuntimeKeys() throws {
        #if MOCKSYN_ENABLE
        let mock = ReturnOverloadedServiceMock()

        mock.given.loadReturningString().willReturn("string")
        mock.given.loadReturningInt().willReturn(42)
        mock.given.loadReturningStringOptional().willReturn("optional")

        let string: String = mock.load()
        let int: Int = mock.load()
        let optional: String? = mock.load()

        XCTAssertEqual(string, "string")
        XCTAssertEqual(int, 42)
        XCTAssertEqual(optional, "optional")

        try mock.verify.loadReturningString().once()
        try mock.verify.loadReturningInt().once()
        try mock.verify.loadReturningStringOptional().once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedReturnTypeOverloadsResolveDslSuffixCollisions() throws {
        #if MOCKSYN_ENABLE
        let mock = CollidingReturnOverloadedServiceMock()
        let namespaced = ReturnOverloadNamespace.Value(raw: "namespaced")
        let flat = ReturnOverloadNamespaceValue(raw: "flat")
        let matchedNamespaced = ReturnOverloadNamespace.Value(raw: "matched-namespaced")
        let matchedFlat = ReturnOverloadNamespaceValue(raw: "matched-flat")

        mock.given.itemReturningReturnOverloadNamespaceValue().willReturn(namespaced)
        mock.given.itemReturningReturnOverloadNamespaceValueOverload2().willReturn(flat)
        mock.given.findReturningReturnOverloadNamespaceValue(id: .value("1")).willReturn(matchedNamespaced)
        mock.given.findReturningReturnOverloadNamespaceValueOverload2(id: .value("1")).willReturn(matchedFlat)

        let resolvedNamespaced: ReturnOverloadNamespace.Value = mock.item()
        let resolvedFlat: ReturnOverloadNamespaceValue = mock.item()
        let resolvedMatchedNamespaced: ReturnOverloadNamespace.Value = mock.find(id: "1")
        let resolvedMatchedFlat: ReturnOverloadNamespaceValue = mock.find(id: "1")

        XCTAssertEqual(resolvedNamespaced, namespaced)
        XCTAssertEqual(resolvedFlat, flat)
        XCTAssertEqual(resolvedMatchedNamespaced, matchedNamespaced)
        XCTAssertEqual(resolvedMatchedFlat, matchedFlat)

        try mock.verify.itemReturningReturnOverloadNamespaceValue().once()
        try mock.verify.itemReturningReturnOverloadNamespaceValueOverload2().once()
        try mock.verify.findReturningReturnOverloadNamespaceValue(id: .value("1")).once()
        try mock.verify.findReturningReturnOverloadNamespaceValueOverload2(id: .value("1")).once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedStaticReturnTypeOverloadsUseReturnDisambiguatedDslAndRuntimeKeys() throws {
        #if MOCKSYN_ENABLE
        StaticReturnOverloadedServiceMock.resetStatic()

        StaticReturnOverloadedServiceMock.given.makeReturningString().willReturn("string")
        StaticReturnOverloadedServiceMock.given.makeReturningInt().willReturn(42)

        let string: String = StaticReturnOverloadedServiceMock.make()
        let int: Int = StaticReturnOverloadedServiceMock.make()

        XCTAssertEqual(string, "string")
        XCTAssertEqual(int, 42)

        try StaticReturnOverloadedServiceMock.verify.makeReturningString().once()
        try StaticReturnOverloadedServiceMock.verify.makeReturningInt().once()
        StaticReturnOverloadedServiceMock.resetStatic()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
