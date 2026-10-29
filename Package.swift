// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "task",
    products: [
        .executable(
            name: "task",
            targets: ["task"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.59.0")
    ],
    targets: [
        .executableTarget(
            name: "task",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency")
            ]
        ),
        .testTarget(
            name: "taskTests",
            dependencies: ["task"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency")
            ]
        )
    ]
)
