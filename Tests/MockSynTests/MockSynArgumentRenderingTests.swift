import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
    func testRuntimeFailuresRenderArgumentsWithRichStableDescriptions() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        let callback: () -> Void = {}

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        XCTAssertThrowsError(
            try runtime.resolveThrowing(
                member: "load(_:_:_:_:_:_:_:_:_:_:)",
                arguments: [
                    "secret",
                    Optional<String>.some("value") as Any,
                    Optional<Int>.some(42) as Any,
                    Optional<Int>.none as Any,
                    ["first", "second"],
                    ["id": "42"],
                    Set(["user", "admin"]),
                    String.self,
                    callback,
                    RichRenderedUser(id: "42"),
                    7,
                ],
                returnType: String.self
            )
        )

        let message = recorder.failures.last?.message ?? ""
        XCTAssertTrue(message.contains(#""secret""#), message)
        XCTAssertTrue(message.contains(#""value""#), message)
        XCTAssertTrue(message.contains("42"), message)
        XCTAssertTrue(message.contains("nil"), message)
        XCTAssertTrue(message.contains(#"["first", "second"]"#), message)
        XCTAssertTrue(message.contains(#"["id": "42"]"#), message)
        XCTAssertTrue(message.contains(#"Set(["admin", "user"])"#), message)
        XCTAssertTrue(message.contains("String.Type"), message)
        XCTAssertTrue(message.contains("<closure>"), message)
        XCTAssertTrue(message.contains(#"RichRenderedUser(id: "42")"#), message)
        XCTAssertTrue(message.contains("7"), message)
    }
}
