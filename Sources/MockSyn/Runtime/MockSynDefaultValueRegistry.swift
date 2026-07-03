import Foundation

/// Registry used by relaxed mocks and stubs when no explicit stub matches.
public enum MockSynDefaultValueRegistry {
    private static let lock = NSRecursiveLock()
    private static var customDefaults: [ObjectIdentifier: Any] = [:]

    /// Registers a custom default value for a return type.
    public static func register<Value>(_ value: Value, for type: Value.Type) {
        lock.lock()
        defer { lock.unlock() }

        customDefaults[ObjectIdentifier(type)] = value
    }

    /// Removes all custom defaults.
    public static func reset() {
        lock.lock()
        defer { lock.unlock() }

        customDefaults.removeAll()
    }

    /// Resolves a default value for a return type.
    public static func value<Value>(for type: Value.Type) -> Value? {
        let key = ObjectIdentifier(type)
        lock.lock()
        let hasCustomValue = customDefaults.keys.contains(key)
        let customValue = customDefaults[key]
        lock.unlock()

        if hasCustomValue {
            return customValue as? Value
        }

        if String(describing: type).hasPrefix("Optional<") {
            let nilValue = Optional<Any>.none as Any
            return nilValue as? Value
        }

        switch type {
        case is String.Type:
            return "" as? Value
        case is Int.Type:
            return 0 as? Value
        case is Bool.Type:
            return false as? Value
        case is Double.Type:
            return 0.0 as? Value
        case is Float.Type:
            return Float(0) as? Value
        case is Void.Type:
            return () as? Value
        default:
            return nil
        }
    }
}
