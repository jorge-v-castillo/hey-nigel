// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HeyNigelWeather",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "HeyNigelWeather",
            targets: ["HeyNigelWeather"]),
    ],
    dependencies: [
        .package(path: "../HeyNigelCore"),
    ],
    targets: [
        .target(
            name: "HeyNigelWeather",
            dependencies: ["HeyNigelCore"]),
        .testTarget(
            name: "HeyNigelWeatherTests",
            dependencies: ["HeyNigelWeather"]
        ),
    ]
)
