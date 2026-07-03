import MockSyn
import XCTest

final class MockSynPublicAPITests: XCTestCase {
    func testModeDescriptionsMatchMacroGeneratedSource() {
        XCTAssertEqual(MockSynMode.strict.generatedSourceName, ".strict")
        XCTAssertEqual(MockSynMode.relaxed.generatedSourceName, ".relaxed")
    }

    func testAccessDescriptionsMatchMacroGeneratedSource() {
        XCTAssertEqual(MockSynAccess.internal.generatedSourceName, "internal")
        XCTAssertEqual(MockSynAccess.public.generatedSourceName, "public")
        XCTAssertEqual(MockSynAccess.package.generatedSourceName, "package")
        XCTAssertEqual(MockSynAccess.fileprivate.generatedSourceName, "fileprivate")
        XCTAssertEqual(MockSynAccess.private.generatedSourceName, "private")
    }

    func testRuntimeStoresDoubleKindAndMode() {
        let runtime = MockSynRuntime(kind: .spy, mode: .relaxed)

        XCTAssertEqual(runtime.kind, .spy)
        XCTAssertEqual(runtime.mode, .relaxed)
    }
}
