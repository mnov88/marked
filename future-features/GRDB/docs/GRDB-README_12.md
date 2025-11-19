The `step` method of the aggregate takes an array of [DatabaseValue](#databasevalue). This array contains as many values as the *argumentCount* parameter (or any number of values, when *argumentCount* is omitted).
The `finalize` method of the aggregate returns the final aggregated [value](#values) (Bool, Int, String, Date, Swift enums, etc.).
SQLite has the opportunity to perform additional optimizations when aggregates are "pure", which means that their result only depends on their inputs. So make sure to set the *pure* argument to true when possible.
**Use custom aggregates in the [query interface](#the-query-interface):**
```swift
// SELECT maxLength("name") FROM player
let request = Player.select { maxLength($0.name) }
try Int.fetchOne(db, request) // Int?
```
## Raw SQLite Pointers
**If not all SQLite APIs are exposed in GRDB, you can still use the [SQLite C Interface](https://www.sqlite.org/c3ref/intro.html) and call [SQLite C functions](https://www.sqlite.org/c3ref/funclist.html).**
To access the C SQLite functions from SQLCipher or the system SQLite, you need to perform an extra import:
```swift
import SQLite3   // System SQLite
import SQLCipher // SQLCipher

let sqliteVersion = String(cString: sqlite3_libversion())
```
Raw pointers to database connections and statements are available through the `Database.sqliteConnection` and `Statement.sqliteStatement` properties:
```swift
try dbQueue.read { db in
    // The raw pointer to a database connection:
    let sqliteConnection = db.sqliteConnection

    // The raw pointer to a statement:
    let statement = try db.makeStatement(sql: "SELECT ...")
    let sqliteStatement = statement.sqliteStatement
}
```
> **Note**
>
> - Those pointers are owned by GRDB: don't close connections or finalize statements created by GRDB.
> - GRDB opens SQLite connections in the "[multi-thread mode](https://www.sqlite.org/threadsafe.html)", which (oddly) means that **they are not thread-safe**. Make sure you touch raw databases and statements inside their dedicated dispatch queues.
> - Use the raw SQLite C Interface at your own risk. GRDB won't prevent you from shooting yourself in the foot.
Records
=======
**On top of the [SQLite API](#sqlite-api), GRDB provides protocols** that help manipulating database rows as regular objects named "records":
```swift
try dbQueue.write { db in
    if var place = try Player.fetchOne(db, id: 1) {
        player.score += 10
        try player.update(db)
    }
}
```
Of course, you need to open a [database connection], and [create database tables](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschema) first.
To define a record type, define a type and extend it with database protocols:
- `FetchableRecord` makes it possible to fetch instances from the database.
- `PersistableRecord` makes it possible to save instances into the database.
- `Codable` (not mandatory) provides ready-made serialization to and from database rows.
- `Identifiable` (not mandatory) provides extra convenience database methods.
To make it easier to customize database requests, also nest a `Columns` enum: 
```swift
struct Player: Codable, Identifiable {
    var id: Int64
    var name: String
    var score: Int
    var team: String?
}

// Add database support
extension Player: FetchableRecord, PersistableRecord {
    enum Columns {
        static let name = Column(CodingKeys.name)
        static let score = Column(CodingKeys.score)
        static let team = Column(CodingKeys.team)
    }
}
```
See more [examples of record definitions](#examples-of-record-definitions) below.
> Note: if you are familiar with Core Data's NSManagedObject or Realm's Object, you may experience a cultural shock: GRDB records are not uniqued, do not auto-update, and do not lazy-load. This is both a purpose, and a consequence of protocol-oriented programming.
>
> Tip: The [Recommended Practices for Designing Record Types](https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/recordrecommendedpractices) guide provides general guidance..
>
> Tip: See the [Demo Applications] for sample apps that uses records.
**Overview**
- [Inserting Records](#inserting-records)
- [Fetching Records](#fetching-records)
- [Updating Records](#updating-records)
- [Deleting Records](#deleting-records)
- [Counting Records](#counting-records)
**Protocols and the Record Class**
