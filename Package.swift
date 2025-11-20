// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownStudio",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MarkdownStudio",
            targets: ["MarkdownStudio"]
        )
    ],
    dependencies: [
        // Ink markdown parser
        .package(url: "https://github.com/JohnSundell/Ink.git", from: "0.5.0"),
        // HTML parsing for URL imports
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        // ZIP compression for export all
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        // GRDB for SQLite database persistence
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.8.0")
    ],
    targets: [
        .target(
            name: "MarkdownStudio",
            dependencies: [
                .product(name: "Ink", package: "Ink"),
                "SwiftSoup",
                "ZIPFoundation",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "MarkdownStudio"
        )
    ]
)
