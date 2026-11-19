// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "QRReaderCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "QRReaderCore", targets: ["QRReaderCore"])
    ],
    targets: [
        .target(
            name: "QRReaderCore",
            path: "QRReader",
            exclude: [
                "Assets.xcassets",
                "Configuration",
                "ContentView.swift",
                "Extensions",
                "Info.plist",
                "LaunchScreen.storyboard",
                "Localizable.xcstrings",
                "Main.swift",
                "QRReader.entitlements",
                "Services",
                "Theme",
                "Views",
                "en.lproj",
                "ja.lproj",
            ],
            sources: [
                "Codable/HistoryItem.swift",
                "Models/QRContent.swift",
                "Models/HistoryRepository.swift",
                "Models/ScanSessionState.swift",
            ]
        ),
        .testTarget(
            name: "QRReaderCoreTests",
            dependencies: ["QRReaderCore"],
            path: "QRReaderTests",
            exclude: ["QRReaderTests.swift", "ScanControllerTests.swift"],
            sources: ["QRReaderCoreTests.swift"]
        ),
    ]
)
