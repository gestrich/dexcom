// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dexcom-package",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "dexcom-product",
            targets: ["dexcom-library-target"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gestrich/swift-utilities.git", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "dexcom-library-target",
            dependencies: [
                .product(name: "swift-utilities", package: "swift-utilities"),
            ]
        ),
        .target(
            name: "dexcom-commandline-target",
            dependencies: [ "dexcom-library-target" ]),
        .testTarget(
            name: "dexcomTests",
            dependencies: ["dexcom-commandline-target"]),
    ]
)
