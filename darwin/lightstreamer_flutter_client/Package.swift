// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "lightstreamer_flutter_client",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "lightstreamer-flutter-client",
            targets: ["lightstreamer_flutter_client"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/Lightstreamer/Lightstreamer-lib-client-swift.git",
            // TODO: Upgrade to version for Server 8.0-alpha when it becomes available.
            branch: "dev-tlcp2.6.0"
        )
    ],
    targets: [
        .target(
            name: "lightstreamer_flutter_client",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(
                    name: "LightstreamerClient",
                    package: "Lightstreamer-lib-client-swift"
                )
            ]
        )
    ]
)