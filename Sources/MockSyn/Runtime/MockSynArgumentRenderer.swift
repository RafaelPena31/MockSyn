import Foundation

enum MockSynArgumentRenderer {
    static func render(_ value: Any) -> String {
        if let type = value as? Any.Type {
            return "\(String(describing: type)).Type"
        }

        if let string = value as? String {
            return String(reflecting: string)
        }

        if String(describing: value) == "(Function)" {
            return "<closure>"
        }

        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case .optional:
            guard let child = mirror.children.first else {
                return "nil"
            }

            return render(child.value)
        case .collection:
            return "[" + mirror.children.map { render($0.value) }.joined(separator: ", ") + "]"
        case .set:
            return "Set([" + mirror.children.map { render($0.value) }.sorted().joined(separator: ", ") + "])"
        case .dictionary:
            let entries = mirror.children.map { child in
                let pair = Array(Mirror(reflecting: child.value).children)
                return "\(render(pair[0].value)): \(render(pair[1].value))"
            }

            return "[" + entries.sorted().joined(separator: ", ") + "]"
        default:
            if let customDebug = value as? CustomDebugStringConvertible {
                return customDebug.debugDescription
            }

            return String(reflecting: value)
        }
    }
}
