import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
    func testMatchersSupportOptionalCollectionAndComposedRules() {
        XCTAssertTrue(MockSynMatcher<String?>.`nil`.erase().matches(Optional<String>.none as Any))
        XCTAssertFalse(MockSynMatcher<String?>.`nil`.erase().matches(Optional<String>.some("value") as Any))
        XCTAssertFalse(MockSynMatcher<String?>.`nil`.erase().matches("value"))
        XCTAssertTrue(MockSynMatcher<String?>.notNil.erase().matches(Optional<String>.some("value") as Any))
        XCTAssertFalse(MockSynMatcher<String?>.notNil.erase().matches(Optional<String>.none as Any))

        XCTAssertTrue(MockSynMatcher<[Int]>.isEmpty.erase().matches([Int]() as Any))
        XCTAssertFalse(MockSynMatcher<[Int]>.isEmpty.erase().matches([1] as Any))
        XCTAssertTrue(MockSynMatcher<[Int]>.contains(2).erase().matches([1, 2, 3] as Any))
        XCTAssertFalse(MockSynMatcher<[Int]>.contains(4).erase().matches([1, 2, 3] as Any))
        XCTAssertTrue(MockSynMatcher<Set<String>>.contains("admin").erase().matches(Set(["admin"]) as Any))
        XCTAssertFalse(MockSynMatcher<Set<String>>.contains("guest").erase().matches(Set(["admin"]) as Any))
        XCTAssertTrue(MockSynMatcher<[String: Int]>.contains(key: "count").erase().matches(["count": 1] as Any))
        XCTAssertFalse(MockSynMatcher<[String: Int]>.contains(key: "missing").erase().matches(["count": 1] as Any))
        XCTAssertTrue(MockSynMatcher<[String: Int]>.contains(key: "count", value: 1).erase().matches(["count": 1] as Any))
        XCTAssertFalse(MockSynMatcher<[String: Int]>.contains(key: "count", value: 2).erase().matches(["count": 1] as Any))

        let positive = MockSynMatcher<Int>.matching { $0 > 0 }
        let even = MockSynMatcher<Int>.matching { $0.isMultiple(of: 2) }

        XCTAssertTrue(MockSynMatcher<Int>.all(positive, even).erase().matches(2))
        XCTAssertFalse(MockSynMatcher<Int>.all(positive, even).erase().matches(3))
        XCTAssertTrue(MockSynMatcher<Int>.all().erase().matches(3))
        XCTAssertTrue(MockSynMatcher<Int>.anyOf(.value(1), .value(2)).erase().matches(2))
        XCTAssertFalse(MockSynMatcher<Int>.anyOf(.value(1), .value(2)).erase().matches(3))
        XCTAssertFalse(MockSynMatcher<Int>.anyOf().erase().matches(1))
        XCTAssertTrue(MockSynMatcher<Int>.value(1).not.erase().matches(2))
        XCTAssertFalse(MockSynMatcher<Int>.value(1).not.erase().matches(1))
    }

    func testArgumentCaptorCapturesMatchingValues() {
        let captor = MockSynArgumentCaptor<String>()
        let matcher = captor.capture()

        XCTAssertNil(captor.value)
        XCTAssertEqual(captor.values, [])
        XCTAssertTrue(matcher.erase().matches("first"))
        XCTAssertTrue(matcher.erase().matches("second"))

        XCTAssertEqual(captor.values, ["first", "second"])
        XCTAssertEqual(captor.value, "second")
    }

    func testClosureCaptorCapturesClosures() {
        let captor = MockSynClosureCaptor<(String) -> String>()
        let matcher = captor.capture()
        let closure: (String) -> String = { "hello \($0)" }

        XCTAssertTrue(matcher.erase().matches(closure))

        XCTAssertEqual(captor.value?("Rafael"), "hello Rafael")
    }
}
