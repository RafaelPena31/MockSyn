import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
    func testConstructorFactoryUsesOriginalZeroArgumentConstructorByDefault() {
        let constructor = MockSynConstructor {
            ConstructedUser(id: "original", name: "Original")
        }

        XCTAssertEqual(constructor(), ConstructedUser(id: "original", name: "Original"))
    }

    func testConstructorFactoryCanReplaceAndRestoreZeroArgumentConstructor() {
        let constructor = MockSynConstructor {
            ConstructedUser(id: "original", name: "Original")
        }
        let interception = constructor.replace {
            ConstructedUser(id: "mock", name: "Mock")
        }

        XCTAssertEqual(constructor(), ConstructedUser(id: "mock", name: "Mock"))

        interception.restore()
        interception.restore()

        XCTAssertEqual(constructor(), ConstructedUser(id: "original", name: "Original"))
    }

    func testConstructorFactoryRestoresReplacementOnTokenDeinit() {
        let constructor = MockSynConstructor {
            ConstructedUser(id: "original", name: "Original")
        }

        do {
            let interception = constructor.replace {
                ConstructedUser(id: "scoped", name: "Scoped")
            }
            XCTAssertEqual(constructor(), ConstructedUser(id: "scoped", name: "Scoped"))
            _ = interception
        }

        XCTAssertEqual(constructor(), ConstructedUser(id: "original", name: "Original"))
    }

    func testConstructorFactoryForwardsOneArgumentToReplacement() {
        let constructor = MockSynConstructor1<String, ConstructedUser> { id in
            ConstructedUser(id: id, name: "Original")
        }
        let interception = constructor.replace { id in
            ConstructedUser(id: id, name: "Mock")
        }

        XCTAssertEqual(constructor("42"), ConstructedUser(id: "42", name: "Mock"))

        interception.restore()

        XCTAssertEqual(constructor("42"), ConstructedUser(id: "42", name: "Original"))
    }

    func testConstructorFactoryForwardsTwoArgumentsToReplacement() {
        let constructor = MockSynConstructor2<String, String, ConstructedUser> { id, name in
            ConstructedUser(id: id, name: name)
        }
        let interception = constructor.replace { id, name in
            ConstructedUser(id: "mock-\(id)", name: name.uppercased())
        }

        XCTAssertEqual(constructor("42", "Rafa"), ConstructedUser(id: "mock-42", name: "RAFA"))

        interception.restore()

        XCTAssertEqual(constructor("42", "Rafa"), ConstructedUser(id: "42", name: "Rafa"))
    }
}
