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
        // Apple's official markdown parser
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
        // HTML parsing for URL imports
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        // ZIP compression for export all
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "MarkdownStudio",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
                "SwiftSoup",
                "ZIPFoundation"
            ],
            path: "MarkdownStudio"
        )
    ]
)
