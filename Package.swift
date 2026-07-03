// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

var dependencies: [Package.Dependency] = []

#if compiler(>=6.4)
dependencies.append(.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "604.0.0-prerelease-2026-06-05"))
#elseif compiler(>=6.0)
dependencies.append(.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"))
#else
dependencies.append(.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "509.0.0"))
#endif

let package = Package(
    name: "MockSyn",
    platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v15), .watchOS(.v6), .macCatalyst(.v15)],
    products: [
        .library(
            name: "MockSyn",
            targets: ["MockSyn"]
        ),
    ],
    dependencies: dependencies,
    targets: [
        .macro(
            name: "MockSynMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),

        .target(
            name: "MockSyn",
            dependencies: ["MockSynMacros"],
            exclude: ["MockSyn.docc"]
        ),

        .testTarget(
            name: "MockSynTests",
            dependencies: ["MockSyn"],
            swiftSettings: [
                .define("MOCKSYN_ENABLE"),
            ]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MockSynMacroTests",
            dependencies: [
                "MockSynMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
