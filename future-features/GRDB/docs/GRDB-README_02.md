</details>
<details>
    <summary>Access to raw SQL</summary>
```swift
try dbQueue.write { db in
    try db.execute(sql: """
        CREATE TABLE player (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          score INT NOT NULL)
        """)
    
    try db.execute(sql: """
        INSERT INTO player (id, name, score)
        VALUES (?, ?, ?)
        """, arguments: ["1", "Arthur", 100])
    
    // Avoid SQL injection with SQL interpolation
    let id = "2"
    let name = "O'Brien"
    let score = 1000
    try db.execute(literal: """
        INSERT INTO player (id, name, score)
        VALUES (\(id), \(name), \(score))
        """)
}
```
See [Executing Updates](#executing-updates)
</details>
<details>
    <summary>Access to raw database rows and values</summary>
```swift
try dbQueue.read { db in
    // Fetch database rows
    let rows = try Row.fetchCursor(db, sql: "SELECT * FROM player")
    while let row = try rows.next() {
        let id: String = row["id"]
        let name: String = row["name"]
        let score: Int = row["score"]
    }
    
    // Fetch values
    let playerCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM player")! // Int
    let playerNames = try String.fetchAll(db, sql: "SELECT name FROM player") // [String]
}

let playerCount = try dbQueue.read { db in
    try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM player")!
}
```
See [Fetch Queries](#fetch-queries)
</details>
<details>
    <summary>Database model types aka "records"</summary>
```swift
struct Player: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: String
    var name: String
    var score: Int
    
    enum Columns {
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
    }
}

try dbQueue.write { db in
    // Create database table
    try db.create(table: "player") { t in
        t.primaryKey("id", .text)
        t.column("name", .text).notNull()
        t.column("score", .integer).notNull()
    }
    
    // Insert a record
    var player = Player(id: "1", name: "Arthur", score: 100)
    try player.insert(db)
    
    // Update a record
    player.score += 10
    try score.update(db)
    
    try player.updateChanges { $0.score += 10 }
    
    // Delete a record
    try player.delete(db)
}
```
See [Records](#records)
</details>
<details>
    <summary>Query the database with the Swift query interface</summary>
```swift
try dbQueue.read { db in
    // Player
    let player = try Player.find(db, id: "1")
    
    // Player?
    let arthur = try Player.filter { $0.name == "Arthur" }.fetchOne(db)
    
    // [Player]
    let bestPlayers = try Player.order(\.score.desc).limit(10).fetchAll(db)
    
    // Int
    let playerCount = try Player.fetchCount(db)
    
    // SQL is always welcome
    let players = try Player.fetchAll(db, sql: "SELECT * FROM player")
}
```
See the [Query Interface](#the-query-interface)
</details>
<details>
    <summary>Database changes notifications</summary>
```swift
// Define the observed value
let observation = ValueObservation.tracking { db in
    try Player.fetchAll(db)
}

// Start observation
let cancellable = observation.start(
    in: dbQueue,
    onError: { error in ... },
    onChange: { (players: [Player]) in print("Fresh players: \(players)") })
```
Ready-made support for Combine and RxSwift:
```swift
// Swift concurrency
for try await players in observation.values(in: dbQueue) {
    print("Fresh players: \(players)")
}

// Combine
let cancellable = observation.publisher(in: dbQueue).sink(
    receiveCompletion: { completion in ... },
    receiveValue: { (players: [Player]) in print("Fresh players: \(players)") })

// RxSwift
let disposable = observation.rx.observe(in: dbQueue).subscribe(
    onNext: { (players: [Player]) in print("Fresh players: \(players)") },
    onError: { error in ... })
```
See [Database Observation], [Combine Support], [RxGRDB].
</details>
Documentation
=============
**GRDB runs on top of SQLite**: you should get familiar with the [SQLite FAQ](http://www.sqlite.org/faq.html). For general and detailed information, jump to the [SQLite Documentation](http://www.sqlite.org/docs.html).
#### Demo Applications & Frequently Asked Questions
- [Demo Applications]
- [FAQ]
#### Reference
- 📖 [GRDB Reference](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/)
#### Getting Started
- [Installation](#installation)
- [Database Connections]: Connect to SQLite databases
#### SQLite and SQL
- [SQLite API](#sqlite-api): The low-level SQLite API &bull; [executing updates](#executing-updates) &bull; [fetch queries](#fetch-queries) &bull; [SQL Interpolation]
#### Records and the Query Interface
- [Records](#records): Fetching and persistence methods for your custom structs and class hierarchies
- [Query Interface](#the-query-interface): A swift way to generate SQL &bull; [create tables, indexes, etc](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschema) &bull; [requests](#requests) • [associations between record types](Documentation/AssociationsBasics.md)
#### Application Tools
- [Migrations]: Transform your database as your application evolves.
- [Full-Text Search]: Perform efficient and customizable full-text searches.
- [Database Observation]: Observe database changes and transactions.
- [Encryption](#encryption): Encrypt your database with SQLCipher.
- [Backup](#backup): Dump the content of a database to another.
- [Interrupt a Database](#interrupt-a-database): Abort any pending database operation.
- [Sharing a Database]: How to share an SQLite database between multiple processes - recommendations for App Group containers, App Extensions, App Sandbox, and file coordination.
#### Good to Know
- [Concurrency]: How to access databases in a multi-threaded application.
- [Combine](Documentation/Combine.md): Access and observe the database with Combine publishers.
- [Avoiding SQL Injection](#avoiding-sql-injection)
- [Error Handling](#error-handling)
- [Unicode](#unicode)
- [Memory Management](#memory-management)
- [Data Protection](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections)
- :bulb: [Migrating From GRDB 6 to GRDB 7](Documentation/GRDB7MigrationGuide.md)
- :bulb: [Why Adopt GRDB?](Documentation/WhyAdoptGRDB.md)
- :bulb: [Recommended Practices for Designing Record Types](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/recordrecommendedpractices)
