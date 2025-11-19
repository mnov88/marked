<picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/groue/GRDB.swift/master/GRDB~dark.png">
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/groue/GRDB.swift/master/GRDB.png">
    <img alt="GRDB: A toolkit for SQLite databases, with a focus on application development." src="https://raw.githubusercontent.com/groue/GRDB.swift/master/GRDB.png">
</picture>
<p align="center">
    <strong>A toolkit for SQLite databases, with a focus on application development</strong><br>
    Proudly serving the community since 2015
</p>
<p align="center">
    <a href="https://developer.apple.com/swift/"><img alt="Swift 6" src="https://img.shields.io/badge/swift-6-orange.svg?style=flat"></a>
    <a href="https://github.com/groue/GRDB.swift/blob/master/LICENSE"><img alt="License" src="https://img.shields.io/github/license/groue/GRDB.swift.svg?maxAge=2592000"></a>
    <a href="https://github.com/groue/GRDB.swift/actions/workflows/CI.yml"><img alt="CI Status" src="https://github.com/groue/GRDB.swift/actions/workflows/CI.yml/badge.svg?branch=master"></a>
</p>
---
<a href="https://menial.co.uk/base/"><img alt="Base: The best SQLite database editor for macOS" src="https://raw.githubusercontent.com/groue/GRDB.swift/master/Sponsors/base.png"></a>
<p align="center">
    <strong>Thank you to <a href="https://menial.co.uk/base/">Base</a> for sponsoring GRDB</strong><br />Base is a small, powerful, comfortable SQLite editor for everyone on macOS.
</p>
---
**Latest release**: October 2, 2025 • [version 7.8.0](https://github.com/groue/GRDB.swift/tree/v7.8.0) • [CHANGELOG](CHANGELOG.md) • [Migrating From GRDB 6 to GRDB 7](Documentation/GRDB7MigrationGuide.md)
**Requirements**: iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 7.0+ &bull; SQLite 3.20.0+ &bull; Swift 6+ / Xcode 16+
**Contact**:
- Release announcements and usage tips: follow [@groue@hachyderm.io](https://hachyderm.io/@groue) on Mastodon.
- Report bugs in a [Github issue](https://github.com/groue/GRDB.swift/issues/new). Make sure you check the [existing issues](https://github.com/groue/GRDB.swift/issues?q=is%3Aopen) first.
- A question? Looking for advice? Do you wonder how to contribute? Fancy a chat? Go to the [GitHub discussions](https://github.com/groue/GRDB.swift/discussions), or the [GRDB forums](https://forums.swift.org/c/related-projects/grdb).
## What is GRDB?
Use this library to save your application’s permanent data into SQLite databases. It comes with built-in tools that address common needs:
- **SQL Generation**
    Enhance your application models with persistence and fetching methods, so that you don't have to deal with SQL and raw database rows when you don't want to.
- **Database Observation**
    Get notifications when database values are modified. 
- **Robust Concurrency**
    Multi-threaded applications can efficiently use their databases, including WAL databases that support concurrent reads and writes. 
- **Migrations**
    Evolve the schema of your database as you ship new versions of your application.
- **Leverage your SQLite skills**
    Not all developers need advanced SQLite features. But when you do, GRDB is as sharp as you want it to be. Come with your SQL and SQLite skills, or learn new ones as you go!
---
<p align="center">
    <a href="#usage">Usage</a> &bull;
    <a href="#documentation">Documentation</a> &bull;
    <a href="#installation">Installation</a> &bull;
    <a href="#faq">FAQ</a>
</p>
---
## Usage
<details open>
  <summary>Start using the database in four steps</summary>
```swift
import GRDB

// 1. Open a database connection
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")

// 2. Define the database schema
try dbQueue.write { db in
    try db.create(table: "player") { t in
        t.primaryKey("id", .text)
        t.column("name", .text).notNull()
        t.column("score", .integer).notNull()
    }
}

// 3. Define a record type
struct Player: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: String
    var name: String
    var score: Int
    
    enum Columns {
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
}

// 4. Write and read in the database
try dbQueue.write { db in
    try Player(id: "1", name: "Arthur", score: 100).insert(db)
    try Player(id: "2", name: "Barbara", score: 1000).insert(db)
}

try dbQueue.read { db in
    let player = try Player.find(db, id: "1"))
    
    let bestPlayers = try Player
        .order(\.score.desc)
        .limit(10)
        .fetchAll(db)
}
```
