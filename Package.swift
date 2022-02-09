// swift-tools-version:5.5

import PackageDescription

extension String {
    static let xcresult = "XCResultConverter"

    static func test(for target: String) -> String { target + "Tests" }
}

extension Target.Dependency {
    static let xcresult: Self = .init(stringLiteral: .xcresult)
}

extension Target.Dependency {
    static let argumentParser: Self = .product(name: "ArgumentParser", package: "swift-argument-parser")
}

let package = Package(
    name: .xcresult,
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "xcrc", targets: [.xcresult])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: .init(1, 0, 3))),
    ],
    targets: [
        .executableTarget(name: .xcresult, dependencies: [.argumentParser]),
        .testTarget(name: .test(for: .xcresult), dependencies: [.argumentParser, .xcresult]),
    ]
)
