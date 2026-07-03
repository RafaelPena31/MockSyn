import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
    func testDefaultValueRegistryProvidesBuiltInDefaultsAndReset() {
        MockSynDefaultValueRegistry.register("custom", for: String.self)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: String.self), "custom")

        MockSynDefaultValueRegistry.register(Optional<String>.none, for: String?.self)
        let customOptional: String?? = MockSynDefaultValueRegistry.value(for: String?.self)
        XCTAssertTrue(customOptional != nil)
        XCTAssertNil(customOptional!)

        MockSynDefaultValueRegistry.reset()

        let optional: String?? = MockSynDefaultValueRegistry.value(for: String?.self)
        let intOptional: Int?? = MockSynDefaultValueRegistry.value(for: Int?.self)
        let void: Void? = MockSynDefaultValueRegistry.value(for: Void.self)

        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: String.self), "")
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Int.self), 0)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Bool.self), false)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Double.self), 0.0)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Float.self), Float(0))
        XCTAssertNotNil(void)
        XCTAssertTrue(optional != nil)
        XCTAssertNil(optional!)
        XCTAssertTrue(intOptional != nil)
        XCTAssertNil(intOptional!)
        XCTAssertNil(MockSynDefaultValueRegistry.value(for: Date.self))
    }
}
