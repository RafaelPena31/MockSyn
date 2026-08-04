#if canImport(Combine)
import Combine
import MockSyn
import XCTest

@Mocking
protocol ObservableMockService: ObservableObject {
    init(seed: String)

    static var globalName: String { get set }

    var name: String { get set }
    var count: Int { get }

    func refresh()
}

@Stubbing
protocol ObservableStubService: Combine.ObservableObject {
    var name: String { get set }

    func refresh()
}

@Spying
protocol ObservableSpyService: ObservableObject {
    var name: String { get set }

    func refresh()
}

private final class RealObservableSpyService: ObservableSpyService {
    let objectWillChange = ObservableObjectPublisher()
    var name = "real"

    func refresh() {}
}

extension MockSynGeneratedTypeIntegrationTests {
    func testObservableMockNotifiesForGetterStubConfigurationAndSetterOnly() {
        #if MOCKSYN_ENABLE
        let mock = ObservableMockServiceMock(seed: "seed")
        var emissionCount = 0
        let subscription = mock.objectWillChange.sink { emissionCount += 1 }

        ObservableMockServiceMock.given.globalName.get.willReturn("global")
        ObservableMockServiceMock.globalName = "updated-global"
        XCTAssertEqual(emissionCount, 0)

        mock.given.refresh().willRun {}
        XCTAssertEqual(emissionCount, 0)

        mock.given.count.get.willReturn(1)
        XCTAssertEqual(emissionCount, 1)

        mock.given.name.get.willRun { "configured" }
        XCTAssertEqual(emissionCount, 2)

        XCTAssertEqual(mock.name, "configured")
        XCTAssertEqual(emissionCount, 2)

        mock.given.name.set(.any).willRun { _ in
            XCTAssertEqual(emissionCount, 3)
        }
        XCTAssertEqual(emissionCount, 2)

        mock.name = "updated"
        XCTAssertEqual(emissionCount, 3)
        withExtendedLifetime(subscription) {}
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testObservableStubUsesTheSameNotificationContract() {
        #if MOCKSYN_ENABLE
        let stub = ObservableStubServiceStub()
        var emissionCount = 0
        let subscription = stub.objectWillChange.sink { emissionCount += 1 }

        stub.given.refresh().willRun {}
        stub.given.name.get.willReturn("configured")
        XCTAssertEqual(emissionCount, 1)

        _ = stub.name
        XCTAssertEqual(emissionCount, 1)

        stub.name = "updated"
        XCTAssertEqual(emissionCount, 2)
        withExtendedLifetime(subscription) {}
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testObservableSpyUsesTheSameNotificationContract() {
        #if MOCKSYN_ENABLE
        let spy = ObservableSpyServiceSpy(wrapping: RealObservableSpyService())
        var emissionCount = 0
        let subscription = spy.objectWillChange.sink { emissionCount += 1 }

        spy.given.refresh().willRun {}
        spy.given.name.get.willReturn("configured")
        XCTAssertEqual(emissionCount, 1)

        XCTAssertEqual(spy.name, "configured")
        XCTAssertEqual(emissionCount, 1)

        spy.name = "updated"
        XCTAssertEqual(emissionCount, 2)
        withExtendedLifetime(subscription) {}
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
#endif
