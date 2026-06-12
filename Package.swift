// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AccessibilityAuditReport",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AccessibilityAuditReport",
            targets: ["AccessibilityAuditReport"]
        ),
        .library(
            name: "AccessibilityAuditXCTestSupport",
            targets: ["AccessibilityAuditXCTestSupport"]
        )
    ],
    targets: [
        .target(name: "AccessibilityAuditReport"),
        .target(
            name: "AccessibilityAuditXCTestSupport",
            dependencies: ["AccessibilityAuditReport"]
        ),
        .testTarget(
            name: "AccessibilityAuditReportTests",
            dependencies: ["AccessibilityAuditReport"]
        ),
        .testTarget(
            name: "AccessibilityAuditXCTestSupportTests",
            dependencies: ["AccessibilityAuditXCTestSupport"]
        )
    ]
)
