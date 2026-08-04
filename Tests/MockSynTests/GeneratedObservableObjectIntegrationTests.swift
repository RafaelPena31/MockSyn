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
    var throwingName: String { get throws }

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

private enum ObservableObjectGetterError: Error, Equatable {
    case configured
}

final class MockSynObservableObjectIntegrationTests: XCTestCase {
    func testObservableObjectMockNotifiesForGetterStubConfigurationAndSetterOnly() {
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

    func testObservableObjectStubUsesTheSameNotificationContract() {
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

    func testObservableObjectSpyUsesTheSameNotificationContract() {
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

    func testObservableObjectThrowingGetterNotifiesForEveryConfiguredBehavior() throws {
        #if MOCKSYN_ENABLE
        let returnMock = ObservableMockServiceMock(seed: "return")
        var returnEmissions = 0
        let returnSubscription = returnMock.objectWillChange.sink { returnEmissions += 1 }

        returnMock.given.throwingName.get.willReturn("returned")
        XCTAssertEqual(returnEmissions, 1)
        XCTAssertEqual(try returnMock.throwingName, "returned")
        XCTAssertEqual(returnEmissions, 1)

        let throwMock = ObservableMockServiceMock(seed: "throw")
        var throwEmissions = 0
        let throwSubscription = throwMock.objectWillChange.sink { throwEmissions += 1 }

        throwMock.given.throwingName.get.willThrow(ObservableObjectGetterError.configured)
        XCTAssertEqual(throwEmissions, 1)
        XCTAssertThrowsError(try throwMock.throwingName) { error in
            XCTAssertEqual(error as? ObservableObjectGetterError, .configured)
        }
        XCTAssertEqual(throwEmissions, 1)

        let runMock = ObservableMockServiceMock(seed: "run")
        var runEmissions = 0
        let runSubscription = runMock.objectWillChange.sink { runEmissions += 1 }

        runMock.given.throwingName.get.willRun { "ran" }
        XCTAssertEqual(runEmissions, 1)
        XCTAssertEqual(try runMock.throwingName, "ran")
        XCTAssertEqual(runEmissions, 1)

        withExtendedLifetime((returnSubscription, throwSubscription, runSubscription)) {}
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testObservableObjectPublisherSerializesConcurrentSends() {
        let publisher = MockSynObservableObjectPublisher()
        let stateLock = NSLock()
        var activeCallbacks = 0
        var detectedOverlap = false
        let subscription = publisher.sink {
            stateLock.lock()
            activeCallbacks += 1
            detectedOverlap = detectedOverlap || activeCallbacks > 1
            stateLock.unlock()

            Thread.sleep(forTimeInterval: 0.001)

            stateLock.lock()
            activeCallbacks -= 1
            stateLock.unlock()
        }

        DispatchQueue.concurrentPerform(iterations: 20) { _ in
            publisher.send()
        }

        XCTAssertFalse(detectedOverlap)
        withExtendedLifetime(subscription) {}
    }

    func testObservableObjectPublisherAllowsReentrantSend() {
        let publisher = MockSynObservableObjectPublisher()
        var emissionCount = 0
        let subscription = publisher.sink {
            emissionCount += 1
            if emissionCount == 1 {
                publisher.send()
            }
        }

        publisher.send()

        XCTAssertEqual(emissionCount, 2)
        withExtendedLifetime(subscription) {}
    }
}
#endif
