// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ForensicCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ForensicCore",
            targets: ["ForensicCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0")
    ],
    targets: [
        .target(
            name: "ForensicCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),
        .testTarget(
            name: "ForensicCoreTests",
            dependencies: ["ForensicCore"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
