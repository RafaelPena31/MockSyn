import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MockSynPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockingMacro.self,
        StubbingMacro.self,
        SpyingMacro.self,
    ]
}
