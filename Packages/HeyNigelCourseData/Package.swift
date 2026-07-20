// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HeyNigelCourseData",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "HeyNigelCourseData",
            targets: ["HeyNigelCourseData"]),
    ],
    dependencies: [
        .package(path: "../HeyNigelCore"),
    ],
    targets: [
        .target(
            name: "HeyNigelCourseData",
            dependencies: ["HeyNigelCore"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "HeyNigelCourseDataTests",
            dependencies: ["HeyNigelCourseData"]
        ),
    ]
)
