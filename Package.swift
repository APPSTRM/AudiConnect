// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudiConnect",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .executable(name: "AudiConnectCLT", targets: ["CommandLineTool"]),
        .library(name: "AudiConnect", targets: ["AudiConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
    ],
    targets: [
        .target(name: "AudiConnect"),
        .executableTarget(
            name: "CommandLineTool",
            dependencies: [
                .target(name: "AudiConnect", condition: .when(platforms: [.macOS])),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser",
                    condition: .when(platforms: [.macOS])
                ),
            ]
        ),
    ]
)
