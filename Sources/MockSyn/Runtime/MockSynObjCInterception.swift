#if canImport(ObjectiveC)
import Foundation
import ObjectiveC.runtime

/// Error reported when MockSyn cannot install an Objective-C runtime interception.
public enum MockSynObjCInterceptionError: Error, Equatable, CustomStringConvertible {
    /// The requested instance method does not exist in the Objective-C runtime.
    case missingInstanceMethod(type: String, selector: String)

    /// The requested class method does not exist in the Objective-C runtime.
    case missingClassMethod(type: String, selector: String)

    public var description: String {
        switch self {
        case .missingInstanceMethod(let type, let selector):
            return "MockSyn could not find Objective-C instance method \(selector) on \(type)."
        case .missingClassMethod(let type, let selector):
            return "MockSyn could not find Objective-C class method \(selector) on \(type)."
        }
    }
}

/// Token that owns a temporary Objective-C method replacement.
///
/// Keep the token alive for the desired interception scope. Calling ``restore()``
/// or releasing the token restores the original Objective-C implementation.
public final class MockSynObjCInterception {
    private let lock = NSLock()
    private let method: Method
    private let originalImplementation: IMP
    private let replacementImplementation: IMP
    private var isRestored = false

    private init(method: Method, replacementBlock: Any) {
        self.method = method
        self.originalImplementation = method_getImplementation(method)
        self.replacementImplementation = imp_implementationWithBlock(replacementBlock)
        method_setImplementation(method, replacementImplementation)
    }

    deinit {
        restore()
    }

    /// Replaces an Objective-C instance method with a block implementation.
    ///
    /// The block signature must match the Objective-C method implementation
    /// convention, including the receiver as the first argument.
    @discardableResult
    public static func replaceInstanceMethod(
        on type: AnyClass,
        selector: Selector,
        with replacementBlock: Any
    ) throws -> MockSynObjCInterception {
        guard let method = class_getInstanceMethod(type, selector) else {
            throw MockSynObjCInterceptionError.missingInstanceMethod(
                type: String(describing: type),
                selector: NSStringFromSelector(selector)
            )
        }

        return MockSynObjCInterception(method: method, replacementBlock: replacementBlock)
    }

    /// Replaces an Objective-C class method with a block implementation.
    ///
    /// The block signature must match the Objective-C method implementation
    /// convention, including the metaclass receiver as the first argument.
    @discardableResult
    public static func replaceClassMethod(
        on type: AnyClass,
        selector: Selector,
        with replacementBlock: Any
    ) throws -> MockSynObjCInterception {
        guard let method = class_getClassMethod(type, selector) else {
            throw MockSynObjCInterceptionError.missingClassMethod(
                type: String(describing: type),
                selector: NSStringFromSelector(selector)
            )
        }

        return MockSynObjCInterception(method: method, replacementBlock: replacementBlock)
    }

    /// Restores the original Objective-C implementation.
    public func restore() {
        lock.lock()
        defer { lock.unlock() }

        guard !isRestored else {
            return
        }

        method_setImplementation(method, originalImplementation)
        imp_removeBlock(replacementImplementation)
        isRestored = true
    }
}
#endif
