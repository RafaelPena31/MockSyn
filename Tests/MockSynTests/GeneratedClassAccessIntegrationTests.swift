import MockSyn
import XCTest

struct GeneratedClassHiddenValue: Equatable {
    let rawValue: String
}

@Mocking
public class PublicMixedAccessServiceBase {
    init(hidden: GeneratedClassHiddenValue) {}

    public init(label: String) {}

    func hiddenMethod() -> GeneratedClassHiddenValue {
        GeneratedClassHiddenValue(rawValue: "base")
    }

    public func visibleMethod() -> String {
        "base"
    }

    var hiddenProperty: GeneratedClassHiddenValue {
        GeneratedClassHiddenValue(rawValue: "base")
    }

    public var visibleProperty: String {
        "base"
    }

    subscript(hidden hidden: GeneratedClassHiddenValue) -> GeneratedClassHiddenValue {
        hidden
    }

    public subscript(index index: Int) -> String {
        "base-\(index)"
    }
}

@Mocking
public class PublicImplicitInitializerServiceBase {
}

extension MockSynGeneratedTypeIntegrationTests {
    func testGeneratedPublicClassPreservesMemberAccessAndStubbing() throws {
        #if MOCKSYN_ENABLE
        let hidden = GeneratedClassHiddenValue(rawValue: "hidden")
        let mock = PublicMixedAccessServiceBaseMock(hidden: hidden)

        mock.given.hiddenMethod().willReturn(hidden)
        mock.given.visibleMethod().willReturn("visible")
        mock.given.hiddenProperty.get.willReturn(hidden)
        mock.given.visibleProperty.get.willReturn("property")
        mock.given.subscript(hidden: .value(hidden)).get.willReturn(hidden)
        mock.given.subscript(index: .value(7)).get.willReturn("seven")

        XCTAssertEqual(mock.hiddenMethod(), hidden)
        XCTAssertEqual(mock.visibleMethod(), "visible")
        XCTAssertEqual(mock.hiddenProperty, hidden)
        XCTAssertEqual(mock.visibleProperty, "property")
        XCTAssertEqual(mock[hidden: hidden], hidden)
        XCTAssertEqual(mock[index: 7], "seven")

        try mock.verify.hiddenMethod().once()
        try mock.verify.visibleMethod().once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedPublicClassKeepsImplicitInitializerInternal() {
        #if MOCKSYN_ENABLE
        let mock = PublicImplicitInitializerServiceBaseMock()

        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
