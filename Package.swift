// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "CurlDSL",
    platforms: [
		.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
	products: [
        .library(
            name: "CurlDSL",
            targets: ["CurlDSL"]),
        .library(
            name: "CurlDSLAsync",
            targets: ["CurlDSL", "CurlDSLAsync"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "CurlDSL",
            dependencies: []),
        .target(
            name: "CurlDSLAsync",
            dependencies: ["CurlDSL"]),
        .testTarget(
            name: "CurlDSLTests",
            dependencies: ["CurlDSL"]),
    ]
)
